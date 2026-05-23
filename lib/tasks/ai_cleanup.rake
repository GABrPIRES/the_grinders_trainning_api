# lib/tasks/ai_cleanup.rake
#
# Tasks de manutenção para dados gerados pelo WeeklyAiDuplicationJob.
#
# Origem: bug de produção em 2026-05-22 19:44 onde retry do GeminiClient::GeminiError
# fazia o WeeklyDuplicationService criar 2 conjuntos de treinos por feedback.
# Sprint 010 corrigiu a causa raiz (idempotência verdadeira), mas os dados
# duplicados em produção precisam ser limpos manualmente.

namespace :ai do
  desc "Apaga conjuntos duplicados de treinos created_by_ai dentro de uma mesma week. " \
       "Mantém o que tem ai_load_suggestions; fallback no mais novo. Use DRY_RUN=true para preview."
  task cleanup_duplicates: :environment do
    dry_run = ENV["DRY_RUN"] == "true"
    total_deleted = 0
    weeks_touched = 0

    puts "=== AI Cleanup Duplicates (DRY_RUN=#{dry_run}) ==="
    Week.find_each do |week|
      groups = week.treinos.where(created_by_ai: true).group_by { |t| [t.name, t.day&.to_date] }
      duplicate_groups = groups.select { |_, treinos| treinos.size > 1 }
      next if duplicate_groups.empty?

      weeks_touched += 1
      puts ""
      puts "Week ##{week.id} (block=#{week.training_block_id}, number=#{week.week_number})"

      duplicate_groups.each do |key, treinos|
        # Mantém o que tem ai_load_suggestions; se nenhum tem, mantém o mais novo
        # (assumimos que o último foi o que completou).
        keeper = treinos.find do |t|
          AiLoadSuggestion.joins(section: { exercicio: :treino })
                          .where(treinos: { id: t.id })
                          .exists?
        end
        keeper ||= treinos.max_by(&:created_at)

        to_delete = treinos - [keeper]
        puts "  Grupo #{key.inspect}: mantém #{keeper.id} (#{keeper.created_at.iso8601}), apaga #{to_delete.map(&:id).join(', ')}"

        unless dry_run
          to_delete.each(&:destroy)
        end
        total_deleted += to_delete.size
      end
    end

    puts ""
    puts "=== Resumo ==="
    puts "Weeks com duplicatas: #{weeks_touched}"
    puts "Treinos #{dry_run ? 'que seriam apagados' : 'apagados'}: #{total_deleted}"
    puts "Use DRY_RUN=true para preview sem apagar." unless dry_run
  end
end

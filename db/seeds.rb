# =============================================================================
# THE GRINDERS — SEED COMPLETO DE DESENVOLVIMENTO
# =============================================================================
# Roda com: bundle exec rails db:seed
# Idempotente: find_or_create_by! onde possível, destrói e recria dados voláteis
# Senha padrão de todos os usuários: Grinders@123
#
# USUÁRIO PRINCIPAL DE TESTE: Sarah Mendes <sarah@thegrinders.com>
# =============================================================================

puts "\n🏋️  THE GRINDERS — Iniciando seed completo...\n\n"

SENHA = "Grinders@123"
HOJE  = Date.today  # 2026-04-30

# =============================================================================
# ADMIN
# =============================================================================
puts "👤 Criando admin..."

admin_user = User.find_or_initialize_by(email: "admin@thegrinders.com")
admin_user.assign_attributes(
  name:             "Admin Sistema",
  password:         SENHA,
  role:             :admin,
  status:           :ativo,
  email_verified_at: Time.current
)
admin_user.save!(validate: false)

AdminSetting.instance.update!(emails_enabled: false, push_enabled: true)

# =============================================================================
# COACHES
# =============================================================================
puts "🏅 Criando coaches..."

# --- Coach 1: Rafael (tem 15 alunos) ---
rafael_user = User.find_or_initialize_by(email: "rafael@thegrinders.com")
rafael_user.assign_attributes(
  name:             "Rafael Silva",
  password:         SENHA,
  role:             :personal,
  status:           :ativo,
  email_verified_at: Time.current
)
rafael_user.save!(validate: false)

rafael = rafael_user.personal || rafael_user.build_personal
rafael.assign_attributes(
  bio:                        "Coach especializado em powerlifting e força máxima. 8 anos de experiência, certificado pela ABPF.",
  phone_number:               "(11) 99999-0001",
  instagram:                  "@rafaelsilvacoach",
  signup_code:                "RAFAEL2026",
  signup_code_expires_at:     1.year.from_now,
  auto_approve_students:      false,
  notifications_enabled:      true,
  email_on_workout_completed: true,
  email_on_workout_missed:    true,
  email_students_on_publish:  true
)
rafael.save!

# --- Coach 2: Marcos (sem alunos) ---
marcos_user = User.find_or_initialize_by(email: "marcos@thegrinders.com")
marcos_user.assign_attributes(
  name:             "Marcos Lima",
  password:         SENHA,
  role:             :personal,
  status:           :ativo,
  email_verified_at: Time.current
)
marcos_user.save!(validate: false)

marcos = marcos_user.personal || marcos_user.build_personal
marcos.assign_attributes(
  bio:            "Especialista em musculação e hipertrofia. CREF ativo. Ex-atleta de fisiculturismo.",
  phone_number:   "(21) 99888-0002",
  instagram:      "@marcoslimafit",
  signup_code:    "MARCOS2026",
  signup_code_expires_at: 1.year.from_now,
  notifications_enabled: true
)
marcos.save!

# --- Coach 3: Camila (sem alunos) ---
camila_user = User.find_or_initialize_by(email: "camila@thegrinders.com")
camila_user.assign_attributes(
  name:             "Camila Torres",
  password:         SENHA,
  role:             :personal,
  status:           :ativo,
  email_verified_at: Time.current
)
camila_user.save!(validate: false)

camila = camila_user.personal || camila_user.build_personal
camila.assign_attributes(
  bio:            "Coach de performance funcional e CrossFit. Atleta masters.",
  phone_number:   "(31) 97777-0003",
  instagram:      "@camilatorrescoach",
  signup_code:    "CAMILA2026",
  signup_code_expires_at: 1.year.from_now,
  notifications_enabled: true
)
camila.save!

# =============================================================================
# PLANOS do Coach Rafael
# =============================================================================
puts "📋 Criando planos..."

plano_basico = Plano.find_or_initialize_by(name: "Básico", personal: rafael)
plano_basico.assign_attributes(description: "Acompanhamento mensal com 3 treinos por semana.", price: 150.0, duration: 30)
plano_basico.save!

plano_premium = Plano.find_or_initialize_by(name: "Premium", personal: rafael)
plano_premium.assign_attributes(description: "Acompanhamento semanal + feedback de treinos + ajuste de carga.", price: 250.0, duration: 30)
plano_premium.save!

plano_elite = Plano.find_or_initialize_by(name: "Elite", personal: rafael)
plano_elite.assign_attributes(description: "Acompanhamento diário, análise de vídeo, consulta nutricional mensal.", price: 350.0, duration: 30)
plano_elite.save!

# =============================================================================
# FORMAS DE PAGAMENTO do Coach Rafael
# =============================================================================
puts "💳 Criando formas de pagamento..."

PaymentMethod.find_or_create_by!(personal: rafael, method_type: :pix) do |pm|
  pm.details = { key_type: "cpf", key_value: "123.456.789-00", holder_name: "Rafael Silva" }
end

PaymentMethod.find_or_create_by!(personal: rafael, method_type: :bank_account) do |pm|
  pm.details = { bank: "Nubank", agency: "0001", account: "12345678-9", holder_name: "Rafael Silva" }
end

# =============================================================================
# MODELOS DE EXERCÍCIO do Coach Rafael
# =============================================================================
puts "🏋️  Criando exercise models..."

exercise_models_data = [
  { name: "Agachamento Livre — Força",     exercise_name: "Agachamento Livre",     load: 120.0, series: 5, reps: "5",   rpe: 8.0, coach_comment: "Descer até 90°, joelhos para fora." },
  { name: "Supino Reto — Força",           exercise_name: "Supino Reto",           load: 90.0,  series: 5, reps: "5",   rpe: 8.0, coach_comment: "Escápulas retraídas, cotovelos ~45°." },
  { name: "Terra Convencional — Força",    exercise_name: "Terra Convencional",    load: 160.0, series: 4, reps: "4",   rpe: 8.5, coach_comment: "Quadril alto, barra colada na canela." },
  { name: "Agachamento — Hipertrofia",     exercise_name: "Agachamento Livre",     load: 100.0, series: 4, reps: "8",   rpe: 7.0, coach_comment: "Foco no tempo de descida (3s)." },
  { name: "Supino — Hipertrofia",          exercise_name: "Supino Reto",           load: 75.0,  series: 4, reps: "10",  rpe: 7.0, coach_comment: "Amplitude completa." },
  { name: "Leg Press 45°",                 exercise_name: "Leg Press 45°",         load: 200.0, series: 4, reps: "12",  rpe: 7.0, coach_comment: nil },
  { name: "Desenvolvimento Militar",       exercise_name: "Desenvolvimento Militar", load: 50.0, series: 4, reps: "8",  rpe: 7.5, coach_comment: "Core rígido, sem extensão lombar." },
  { name: "Remada Curvada",                exercise_name: "Remada Curvada",        load: 70.0,  series: 4, reps: "8",   rpe: 7.0, coach_comment: nil },
  { name: "Terra Romeno",                  exercise_name: "Terra Romeno",          load: 80.0,  series: 3, reps: "12",  rpe: 7.0, coach_comment: "Sentir o alongamento nos isquiotibiais." },
  { name: "Rosca Direta",                  exercise_name: "Rosca Direta",          load: 30.0,  series: 3, reps: "12",  rpe: 6.5, coach_comment: nil },
]

exercise_models_data.each do |em|
  ExerciseModel.find_or_create_by!(coach: rafael, name: em[:name]) do |e|
    e.assign_attributes(em.except(:name))
    e.load_unit = "kg"
  end
end

# =============================================================================
# HELPER: cria seções de um exercício
# =============================================================================
def criar_sections(exercicio, series_data)
  exercicio.sections.destroy_all
  series_data.each do |s|
    exercicio.sections.create!(s)
  end
end

# =============================================================================
# ALUNOS DO COACH RAFAEL
# =============================================================================
puts "👥 Criando 15 alunos..."

alunos_data = [
  # [0] Sarah — PRINCIPAL (blocos, pagamentos, feedbacks completos)
  { name: "Sarah Mendes",     email: "sarah@thegrinders.com",    phone: "(11) 91234-5600", birth: "1997-03-15", weight: 62.0, height: 1.65, obj: "Aumentar força no powerlifting e bater PRs.", treinos_sem: 4, tempo: 75, horario: 1, pr_sup: 60, pr_ter: 90, pr_agach: 80 },
  # [1] Gustavo — tem bloco de treinos
  { name: "Gustavo Ferreira", email: "gustavo@thegrinders.com",  phone: "(11) 91234-5601", birth: "1995-07-22", weight: 85.0, height: 1.78, obj: "Ganho de massa muscular com foco em força.", treinos_sem: 3, tempo: 60, horario: 0, pr_sup: 100, pr_ter: 150, pr_agach: 130 },
  # [2] Beatriz — tem bloco de treinos
  { name: "Beatriz Souza",    email: "beatriz@thegrinders.com",  phone: "(21) 91234-5602", birth: "2000-11-08", weight: 55.0, height: 1.60, obj: "Condicionamento geral e perda de gordura.", treinos_sem: 3, tempo: 60, horario: 2, pr_sup: 40, pr_ter: 60, pr_agach: 55 },
  # [3-14] Demais alunos — apenas perfil completo
  { name: "Lucas Andrade",    email: "lucas@thegrinders.com",    phone: "(11) 91234-5603", birth: "1993-05-10", weight: 78.0, height: 1.75, obj: "Melhorar performance no levantamento básico.", treinos_sem: 4, tempo: 90, horario: 1, pr_sup: 90,  pr_ter: 140, pr_agach: 120 },
  { name: "Fernanda Costa",   email: "fernanda@thegrinders.com", phone: "(31) 91234-5604", birth: "1999-01-25", weight: 58.0, height: 1.63, obj: "Preparação para competição amadora.", treinos_sem: 5, tempo: 90, horario: 0, pr_sup: 52,  pr_ter: 80,  pr_agach: 70  },
  { name: "Bruno Martins",    email: "bruno@thegrinders.com",    phone: "(41) 91234-5605", birth: "1990-09-14", weight: 92.0, height: 1.82, obj: "Manutenção de força e saúde articular.", treinos_sem: 3, tempo: 60, horario: 2, pr_sup: 120, pr_ter: 180, pr_agach: 160 },
  { name: "Juliana Lima",     email: "juliana@thegrinders.com",  phone: "(51) 91234-5606", birth: "2002-04-03", weight: 50.0, height: 1.58, obj: "Primeiro bloco de força — iniciante.", treinos_sem: 3, tempo: 60, horario: 1, pr_sup: 30,  pr_ter: 50,  pr_agach: 45  },
  { name: "Pedro Gomes",      email: "pedro@thegrinders.com",    phone: "(61) 91234-5607", birth: "1988-12-19", weight: 88.0, height: 1.80, obj: "Melhorar Wilks score para competir.", treinos_sem: 5, tempo: 120, horario: 0, pr_sup: 130, pr_ter: 200, pr_agach: 180 },
  { name: "Mariana Rocha",    email: "mariana@thegrinders.com",  phone: "(71) 91234-5608", birth: "1996-08-07", weight: 65.0, height: 1.68, obj: "Hipertrofia e definição muscular.", treinos_sem: 4, tempo: 75, horario: 1, pr_sup: 55,  pr_ter: 75,  pr_agach: 65  },
  { name: "Thiago Nascimento",email: "thiago@thegrinders.com",   phone: "(81) 91234-5609", birth: "1992-02-28", weight: 95.0, height: 1.84, obj: "Ganho de força bruta.", treinos_sem: 4, tempo: 90, horario: 2, pr_sup: 140, pr_ter: 220, pr_agach: 200 },
  { name: "Camila Reis",      email: "c.reis@thegrinders.com",   phone: "(91) 91234-5610", birth: "2001-06-16", weight: 52.0, height: 1.61, obj: "Emagrecimento e tônus muscular.", treinos_sem: 3, tempo: 60, horario: 1, pr_sup: 32,  pr_ter: 48,  pr_agach: 42  },
  { name: "Rafael Junior",    email: "rjunior@thegrinders.com",  phone: "(11) 91234-5611", birth: "1994-10-30", weight: 82.0, height: 1.77, obj: "Treinamento de força para saúde.", treinos_sem: 3, tempo: 60, horario: 0, pr_sup: 95,  pr_ter: 145, pr_agach: 125 },
  { name: "Ana Oliveira",     email: "ana@thegrinders.com",      phone: "(21) 91234-5612", birth: "1998-07-12", weight: 60.0, height: 1.65, obj: "Preparação para maratona + força base.", treinos_sem: 4, tempo: 75, horario: 2, pr_sup: 45,  pr_ter: 65,  pr_agach: 58  },
  { name: "Diego Carvalho",   email: "diego@thegrinders.com",    phone: "(31) 91234-5613", birth: "1991-03-05", weight: 90.0, height: 1.81, obj: "Off-season de culturismo.", treinos_sem: 5, tempo: 90, horario: 1, pr_sup: 125, pr_ter: 190, pr_agach: 170 },
  { name: "Larissa Nunes",    email: "larissa@thegrinders.com",  phone: "(41) 91234-5614", birth: "2003-09-21", weight: 48.0, height: 1.56, obj: "Ganho de força e autoconfiança.", treinos_sem: 3, tempo: 60, horario: 2, pr_sup: 28,  pr_ter: 42,  pr_agach: 38  },
]

alunos_criados = alunos_data.map do |d|
  u = User.find_or_initialize_by(email: d[:email])
  u.assign_attributes(name: d[:name], password: SENHA, role: :aluno, status: :ativo, email_verified_at: Time.current)
  u.save!(validate: false)

  a = u.aluno || u.build_aluno
  a.assign_attributes(
    personal:          rafael,
    phone_number:      d[:phone],
    birth_date:        d[:birth],
    weight:            d[:weight],
    height:            d[:height],
    objetivo:          d[:obj],
    treinos_semana:    d[:treinos_sem],
    tempo_treino:      d[:tempo],
    horario_treino:    d[:horario],
    pr_supino:         d[:pr_sup],
    pr_terra:          d[:pr_ter],
    pr_agachamento:    d[:pr_agach],
    new_pr_supino:     nil,
    new_pr_terra:      nil,
    new_pr_agachamento: nil,
    lesao:             [nil, nil, "Tendinite leve no ombro direito (controlada).", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil][alunos_data.index(d)],
    restricao_medica:  nil
  )
  a.save!
  { user: u, aluno: a, data: d }
end

sarah    = alunos_criados[0]
gustavo  = alunos_criados[1]
beatriz  = alunos_criados[2]

# =============================================================================
# ASSINATURAS E PAGAMENTOS
# =============================================================================
puts "💰 Criando assinaturas e pagamentos..."

def criar_pagamentos(aluno, personal, plano, meses_pagos, status_atual)
  assinatura = Assinatura.find_or_initialize_by(aluno: aluno)
  assinatura.assign_attributes(
    plano:      plano,
    start_date: meses_pagos.months.ago,
    end_date:   1.month.from_now,
    status:     :ativo
  )
  assinatura.save!

  meses_pagos.times do |i|
    mes_ref = (meses_pagos - i).months.ago
    Pagamento.find_or_create_by!(aluno: aluno, due_date: mes_ref.beginning_of_month + 5.days) do |p|
      p.amount    = plano.price
      p.personal  = personal
      p.status    = :pago
      p.paid_at   = mes_ref.beginning_of_month + 3.days
    end
  end

  # Pagamento do mês atual com status variável
  Pagamento.find_or_create_by!(aluno: aluno, due_date: Date.today.beginning_of_month + 5.days) do |p|
    p.amount   = plano.price
    p.personal = personal
    p.status   = status_atual
    p.paid_at  = (status_atual == :pago ? Date.today - 2.days : nil)
  end
end

criar_pagamentos(sarah[:aluno],   rafael, plano_elite,   4, :pendente)
criar_pagamentos(gustavo[:aluno], rafael, plano_premium, 2, :pago)
criar_pagamentos(beatriz[:aluno], rafael, plano_basico,  3, :atrasado)

# Demais alunos — 1 pagamento cada com status variado
statuses = [:pago, :pago, :pendente, :pago, :atrasado, :pago, :pendente, :pago, :pago, :atrasado, :pago, :pago]
alunos_criados[3..].each_with_index do |a, i|
  plano = [plano_basico, plano_premium, plano_elite].sample
  assinatura = Assinatura.find_or_initialize_by(aluno: a[:aluno])
  assinatura.assign_attributes(plano: plano, start_date: 1.month.ago, end_date: 1.month.from_now, status: :ativo)
  assinatura.save!

  Pagamento.find_or_create_by!(aluno: a[:aluno], due_date: Date.today.beginning_of_month + 5.days) do |p|
    p.amount   = plano.price
    p.personal = rafael
    p.status   = statuses[i] || :pendente
    p.paid_at  = (statuses[i] == :pago ? Date.today - 5.days : nil)
  end
end

# =============================================================================
# BLOCO DE TREINOS — SARAH (PRINCIPAL)
# Bloco atual em andamento: semana 4 de 8
# =============================================================================
puts "📅 Criando bloco de treinos da Sarah..."

block_start = HOJE - 21.days  # semana 4 atual (iniciou 3 semanas atrás)
block_end   = block_start + 55.days

sarah_block = TrainingBlock.find_or_initialize_by(aluno: sarah[:aluno], title: "Especialização em Força — 8 semanas")
sarah_block.assign_attributes(
  personal:       rafael,
  weeks_duration: 8,
  start_date:     block_start,
  end_date:       block_end
)
sarah_block.save!

# 8 semanas
semanas_sarah = 8.times.map do |i|
  ws = block_start + (i * 7).days
  we = ws + 6.days
  goal = i < 2 ? :overload : (i == 6 ? :deload : :overload)
  week = Week.find_or_initialize_by(training_block: sarah_block, week_number: i + 1)
  week.assign_attributes(start_date: ws, end_date: we, periodization_goal: goal, feedback_enabled: true)
  week.save!
  week
end

# --- Helper para criar treino com exercícios e seções ---
def criar_treino(week:, personal:, name:, day_offset:, status:, exercicios:, started_at: nil, finished_at: nil)
  day = week.start_date.to_datetime + day_offset.days + 9.hours
  treino = Treino.find_or_initialize_by(week: week, name: name)
  treino.assign_attributes(
    personal:    personal,
    day:         day,
    status:      status,
    started_at:  started_at,
    finished_at: finished_at
  )
  treino.save!

  exercicios.each do |ex_data|
    ex = treino.exercicios.find_or_initialize_by(name: ex_data[:name])
    ex.assign_attributes(
      observation:   ex_data[:obs],
      coach_comment: ex_data[:coach_comment],
      video_link:    ex_data[:video_link]
    )
    ex.save!

    ex.sections.destroy_all
    ex_data[:sections].each do |s|
      ex.sections.create!(s)
    end
  end

  treino
end

# Dados de exercícios base reutilizáveis
def agachamento_sections(completed: false, carga: 80.0)
  3.times.map do
    s = { series: 5, reps: 5, carga: carga, rpe: 8.0, load_unit: "kg", equip: "Barra olímpica", feito: completed }
    if completed
      s[:actual_load] = carga
      s[:actual_rpe]  = 8.0 + rand(-0.5..0.5).round(1)
    end
    s
  end
end

def supino_sections(completed: false, carga: 60.0)
  3.times.map do
    s = { series: 5, reps: 5, carga: carga, rpe: 8.0, load_unit: "kg", equip: "Barra olímpica", feito: completed }
    if completed
      s[:actual_load] = carga
      s[:actual_rpe]  = 8.0 + rand(-0.5..0.5).round(1)
    end
    s
  end
end

def terra_sections(completed: false, carga: 90.0)
  2.times.map do
    s = { series: 4, reps: 4, carga: carga, rpe: 8.5, load_unit: "kg", equip: "Barra olímpica", feito: completed }
    if completed
      s[:actual_load] = carga
      s[:actual_rpe]  = 8.5 + rand(-0.5..0.5).round(1)
    end
    s
  end
end

def acessorio_sections(completed: false, carga: 30.0, series: 3, reps: 10)
  series.times.map do
    s = { series: series, reps: reps, carga: carga, rpe: 7.0, load_unit: "kg", feito: completed }
    if completed
      s[:actual_load] = carga
      s[:actual_rpe]  = 7.0
    end
    s
  end
end

# --- SEMANAS 1, 2, 3: todas completas ---
[semanas_sarah[0], semanas_sarah[1], semanas_sarah[2]].each_with_index do |week, wi|
  carga_agach = 80.0 + (wi * 2.5)
  carga_sup   = 57.5 + (wi * 2.5)
  carga_terra = 87.5 + (wi * 2.5)

  # Treino A — Agachamento
  criar_treino(
    week: week, personal: rafael,
    name: "Treino A — Agachamento", day_offset: 0, status: :completed,
    started_at:  week.start_date.to_datetime + 9.hours,
    finished_at: week.start_date.to_datetime + 10.hours + 15.minutes,
    exercicios: [
      {
        name: "Agachamento Livre", obs: "Foco na profundidade.", coach_comment: "Manter joelhos sobre os pés.", video_link: nil,
        sections: agachamento_sections(completed: true, carga: carga_agach)
      },
      {
        name: "Leg Press 45°", obs: nil, coach_comment: nil, video_link: nil,
        sections: acessorio_sections(completed: true, carga: 180.0, series: 3, reps: 10)
      },
      {
        name: "Cadeira Extensora", obs: nil, coach_comment: nil, video_link: nil,
        sections: acessorio_sections(completed: true, carga: 40.0, series: 3, reps: 12)
      }
    ]
  )

  # Treino B — Supino
  criar_treino(
    week: week, personal: rafael,
    name: "Treino B — Supino", day_offset: 2, status: :completed,
    started_at:  (week.start_date + 2.days).to_datetime + 9.hours,
    finished_at: (week.start_date + 2.days).to_datetime + 10.hours + 10.minutes,
    exercicios: [
      {
        name: "Supino Reto", obs: "Barra com pausa no peito.", coach_comment: "Escápulas fixas no banco.", video_link: nil,
        sections: supino_sections(completed: true, carga: carga_sup)
      },
      {
        name: "Supino Inclinado", obs: nil, coach_comment: nil, video_link: nil,
        sections: acessorio_sections(completed: true, carga: 45.0, series: 3, reps: 10)
      },
      {
        name: "Desenvolvimento Militar", obs: nil, coach_comment: "Core rígido.", video_link: nil,
        sections: acessorio_sections(completed: true, carga: 35.0, series: 3, reps: 8)
      }
    ]
  )

  # Treino C — Terra
  criar_treino(
    week: week, personal: rafael,
    name: "Treino C — Terra", day_offset: 4, status: :completed,
    started_at:  (week.start_date + 4.days).to_datetime + 9.hours,
    finished_at: (week.start_date + 4.days).to_datetime + 10.hours + 20.minutes,
    exercicios: [
      {
        name: "Terra Convencional", obs: "Tempo de configuração antes de cada levantamento.", coach_comment: "Barra colada na canela.", video_link: nil,
        sections: terra_sections(completed: true, carga: carga_terra)
      },
      {
        name: "Terra Romeno", obs: nil, coach_comment: nil, video_link: nil,
        sections: acessorio_sections(completed: true, carga: 60.0, series: 3, reps: 10)
      },
      {
        name: "Remada Curvada", obs: nil, coach_comment: nil, video_link: nil,
        sections: acessorio_sections(completed: true, carga: 55.0, series: 4, reps: 8)
      }
    ]
  )
end

# --- SEMANA 4 (ATUAL): Treino A concluído, B em andamento, C publicado ---
week_atual = semanas_sarah[3]  # semana 4

# Treino A — concluído hoje
criar_treino(
  week: week_atual, personal: rafael,
  name: "Treino A — Agachamento", day_offset: 0, status: :completed,
  started_at:  week_atual.start_date.to_datetime + 9.hours,
  finished_at: week_atual.start_date.to_datetime + 10.hours + 20.minutes,
  exercicios: [
    {
      name: "Agachamento Livre", obs: "Semana de pico — vai com tudo!", coach_comment: "Tentar bater PR de 3RM.", video_link: nil,
      sections: agachamento_sections(completed: true, carga: 87.5)
    },
    {
      name: "Leg Press 45°", obs: nil, coach_comment: nil, video_link: nil,
      sections: acessorio_sections(completed: true, carga: 200.0, series: 3, reps: 8)
    }
  ]
)

# Treino B — em andamento (sem seções completas)
criar_treino(
  week: week_atual, personal: rafael,
  name: "Treino B — Supino", day_offset: 2, status: :in_progress,
  started_at: (week_atual.start_date + 2.days).to_datetime + 9.hours,
  exercicios: [
    {
      name: "Supino Reto", obs: nil, coach_comment: "PR de 3RM hoje!", video_link: nil,
      sections: [
        { series: 5, reps: 5, carga: 65.0, rpe: 8.5, load_unit: "kg", feito: true,  actual_load: 65.0, actual_rpe: 8.5 },
        { series: 5, reps: 5, carga: 65.0, rpe: 8.5, load_unit: "kg", feito: false, actual_load: nil,  actual_rpe: nil },
        { series: 5, reps: 5, carga: 65.0, rpe: 8.5, load_unit: "kg", feito: false, actual_load: nil,  actual_rpe: nil },
      ]
    },
    {
      name: "Desenvolvimento Militar", obs: nil, coach_comment: nil, video_link: nil,
      sections: acessorio_sections(completed: false, carga: 40.0, series: 3, reps: 8)
    }
  ]
)

# Treino C — publicado (futuro da semana)
criar_treino(
  week: week_atual, personal: rafael,
  name: "Treino C — Terra", day_offset: 4, status: :published,
  exercicios: [
    {
      name: "Terra Convencional", obs: nil, coach_comment: "Semana pesada — foco total.", video_link: nil,
      sections: terra_sections(completed: false, carga: 95.0)
    },
    {
      name: "Terra Romeno", obs: nil, coach_comment: nil, video_link: nil,
      sections: acessorio_sections(completed: false, carga: 65.0, series: 3, reps: 10)
    }
  ]
)

# --- SEMANAS 5, 6, 7 — Publicadas (treinos planejados) ---
[semanas_sarah[4], semanas_sarah[5], semanas_sarah[6]].each_with_index do |week, i|
  carga_agach = 90.0 + (i * 2.5)
  carga_sup   = 67.5 + (i * 2.5)
  carga_terra = 97.5 + (i * 2.5)

  criar_treino(
    week: week, personal: rafael, name: "Treino A — Agachamento", day_offset: 0, status: :published,
    exercicios: [
      { name: "Agachamento Livre", obs: nil, coach_comment: nil, video_link: nil, sections: agachamento_sections(carga: carga_agach) },
      { name: "Leg Press 45°",     obs: nil, coach_comment: nil, video_link: nil, sections: acessorio_sections(carga: 200.0, series: 3, reps: 8) }
    ]
  )
  criar_treino(
    week: week, personal: rafael, name: "Treino B — Supino", day_offset: 2, status: :published,
    exercicios: [
      { name: "Supino Reto",          obs: nil, coach_comment: nil, video_link: nil, sections: supino_sections(carga: carga_sup) },
      { name: "Desenvolvimento Militar", obs: nil, coach_comment: nil, video_link: nil, sections: acessorio_sections(carga: 40.0, series: 3, reps: 8) }
    ]
  )
  criar_treino(
    week: week, personal: rafael, name: "Treino C — Terra", day_offset: 4, status: :published,
    exercicios: [
      { name: "Terra Convencional", obs: nil, coach_comment: nil, video_link: nil, sections: terra_sections(carga: carga_terra) },
      { name: "Remada Curvada",     obs: nil, coach_comment: nil, video_link: nil, sections: acessorio_sections(carga: 60.0, series: 4, reps: 8) }
    ]
  )
end

# --- SEMANA 8 — Deload (rascunho) ---
deload_week = semanas_sarah[7]
criar_treino(
  week: deload_week, personal: rafael, name: "Treino A — Deload Agachamento", day_offset: 0, status: :draft,
  exercicios: [
    { name: "Agachamento Livre", obs: "Deload — 50% da carga máxima.", coach_comment: "Foco na técnica.", video_link: nil,
      sections: [{ series: 3, reps: 5, carga: 55.0, rpe: 5.0, load_unit: "kg", feito: false }] }
  ]
)

# =============================================================================
# WEEKLY FEEDBACKS — Sarah (semanas 1, 2, 3 completas)
# =============================================================================
puts "📝 Criando feedbacks semanais da Sarah..."

feedbacks_sarah = [
  { semana: semanas_sarah[0], sleep: 4, stress: 2, diet: 4, weight: 62.0, desire: 5, eval: "Ótima semana! Me senti muito bem nos treinos, a técnica do agachamento está melhorando." },
  { semana: semanas_sarah[1], sleep: 3, stress: 3, diet: 3, weight: 61.8, desire: 4, eval: "Semana corrida no trabalho, mas consegui fazer todos os treinos. Um pouco mais cansada." },
  { semana: semanas_sarah[2], sleep: 5, stress: 1, diet: 5, weight: 62.2, desire: 5, eval: "Melhor semana até agora! Bati PR no supino (62,5kg). Animada para as próximas semanas." },
]

feedbacks_sarah.each do |f|
  WeeklyFeedback.find_or_create_by!(week: f[:semana], aluno: sarah[:aluno]) do |fb|
    fb.sleep_level       = f[:sleep]
    fb.stress_level      = f[:stress]
    fb.diet_level        = f[:diet]
    fb.body_weight       = f[:weight]
    fb.training_desire   = f[:desire]
    fb.general_evaluation = f[:eval]
  end
end

# =============================================================================
# BLOCO DE TREINOS — GUSTAVO (em andamento, semana 2 de 5)
# =============================================================================
puts "📅 Criando bloco de treinos do Gustavo..."

gus_block_start = HOJE - 7.days  # semana 2
gus_block_end   = gus_block_start + 34.days

gus_block = TrainingBlock.find_or_initialize_by(aluno: gustavo[:aluno], title: "Hipertrofia Base — 5 semanas")
gus_block.assign_attributes(personal: rafael, weeks_duration: 5, start_date: gus_block_start, end_date: gus_block_end)
gus_block.save!

semanas_gus = 5.times.map do |i|
  ws = gus_block_start + (i * 7).days
  week = Week.find_or_initialize_by(training_block: gus_block, week_number: i + 1)
  week.assign_attributes(start_date: ws, end_date: ws + 6.days, periodization_goal: i == 4 ? :deload : :overload, feedback_enabled: true)
  week.save!
  week
end

# Semana 1 — completa
criar_treino(
  week: semanas_gus[0], personal: rafael, name: "Treino A — Peito e Tríceps", day_offset: 0, status: :completed,
  started_at: (semanas_gus[0].start_date).to_datetime + 9.hours,
  finished_at: (semanas_gus[0].start_date).to_datetime + 10.hours,
  exercicios: [
    { name: "Supino Reto", obs: nil, coach_comment: nil, video_link: nil, sections: supino_sections(completed: true, carga: 100.0) },
    { name: "Crucifixo", obs: nil, coach_comment: nil, video_link: nil, sections: acessorio_sections(completed: true, carga: 18.0, series: 3, reps: 12) },
    { name: "Tríceps Corda", obs: nil, coach_comment: nil, video_link: nil, sections: acessorio_sections(completed: true, carga: 25.0, series: 4, reps: 12) }
  ]
)
criar_treino(
  week: semanas_gus[0], personal: rafael, name: "Treino B — Costas e Bíceps", day_offset: 3, status: :completed,
  started_at: (semanas_gus[0].start_date + 3.days).to_datetime + 9.hours,
  finished_at: (semanas_gus[0].start_date + 3.days).to_datetime + 10.hours + 5.minutes,
  exercicios: [
    { name: "Remada Curvada", obs: nil, coach_comment: nil, video_link: nil, sections: acessorio_sections(completed: true, carga: 70.0, series: 4, reps: 8) },
    { name: "Puxada Frente", obs: nil, coach_comment: nil, video_link: nil, sections: acessorio_sections(completed: true, carga: 60.0, series: 4, reps: 10) },
    { name: "Rosca Direta", obs: nil, coach_comment: nil, video_link: nil, sections: acessorio_sections(completed: true, carga: 35.0, series: 3, reps: 12) }
  ]
)

# Semana 2 (atual) — um publicado
criar_treino(
  week: semanas_gus[1], personal: rafael, name: "Treino A — Peito e Tríceps", day_offset: 0, status: :published,
  exercicios: [
    { name: "Supino Reto", obs: nil, coach_comment: nil, video_link: nil, sections: supino_sections(carga: 102.5) },
    { name: "Crucifixo", obs: nil, coach_comment: nil, video_link: nil, sections: acessorio_sections(carga: 20.0, series: 3, reps: 12) }
  ]
)
criar_treino(
  week: semanas_gus[1], personal: rafael, name: "Treino B — Costas e Bíceps", day_offset: 3, status: :published,
  exercicios: [
    { name: "Remada Curvada", obs: nil, coach_comment: nil, video_link: nil, sections: acessorio_sections(carga: 72.5, series: 4, reps: 8) },
    { name: "Puxada Frente", obs: nil, coach_comment: nil, video_link: nil, sections: acessorio_sections(carga: 62.5, series: 4, reps: 10) }
  ]
)

# Semanas 3-5 — rascunho
[semanas_gus[2], semanas_gus[3], semanas_gus[4]].each_with_index do |week, i|
  criar_treino(
    week: week, personal: rafael, name: "Treino A — Peito e Tríceps", day_offset: 0, status: :draft,
    exercicios: [{ name: "Supino Reto", obs: nil, coach_comment: nil, video_link: nil, sections: supino_sections(carga: 105.0 + i * 2.5) }]
  )
end

# Feedback semana 1 do Gustavo
WeeklyFeedback.find_or_create_by!(week: semanas_gus[0], aluno: gustavo[:aluno]) do |fb|
  fb.sleep_level        = 3
  fb.stress_level       = 3
  fb.diet_level         = 4
  fb.body_weight        = 85.0
  fb.training_desire    = 4
  fb.general_evaluation = "Primeira semana boa. Me adaptando ao volume. Achei o supino pesado mas consegui fechar."
end

# =============================================================================
# BLOCO DE TREINOS — BEATRIZ (quase no fim, semana 6 de 6)
# =============================================================================
puts "📅 Criando bloco de treinos da Beatriz..."

beat_block_start = HOJE - 35.days  # 5 semanas atrás
beat_block_end   = beat_block_start + 41.days

beat_block = TrainingBlock.find_or_initialize_by(aluno: beatriz[:aluno], title: "Condicionamento Geral — 6 semanas")
beat_block.assign_attributes(personal: rafael, weeks_duration: 6, start_date: beat_block_start, end_date: beat_block_end)
beat_block.save!

semanas_beat = 6.times.map do |i|
  ws = beat_block_start + (i * 7).days
  week = Week.find_or_initialize_by(training_block: beat_block, week_number: i + 1)
  week.assign_attributes(start_date: ws, end_date: ws + 6.days, periodization_goal: i == 5 ? :maintenance : :overload, feedback_enabled: true)
  week.save!
  week
end

# Semanas 1-5 — todas completas
5.times do |i|
  week = semanas_beat[i]
  [:published, :completed, :completed, :completed, :completed][i]  # semana 1 foi publicada, resto concluída
  status_final = i == 0 ? :published : :completed

  criar_treino(
    week: week, personal: rafael, name: "Treino Full Body A", day_offset: 0,
    status: i < 5 ? :completed : :published,
    started_at:  i < 5 ? week.start_date.to_datetime + 8.hours : nil,
    finished_at: i < 5 ? week.start_date.to_datetime + 9.hours : nil,
    exercicios: [
      { name: "Agachamento Goblet", obs: nil, coach_comment: nil, video_link: nil,
        sections: [{ series: 3, reps: 15, carga: 20.0, rpe: 7.0, load_unit: "kg", feito: i < 5, actual_load: i < 5 ? 20.0 : nil, actual_rpe: i < 5 ? 7.0 : nil }] },
      { name: "Flexão de Braços", obs: nil, coach_comment: nil, video_link: nil,
        sections: [{ series: 3, reps: 12, carga: 0.0, rpe: 6.0, load_unit: "kg", feito: i < 5, actual_load: i < 5 ? 0.0 : nil, actual_rpe: i < 5 ? 6.0 : nil }] }
    ]
  )
  criar_treino(
    week: week, personal: rafael, name: "Treino Full Body B", day_offset: 3,
    status: i < 5 ? :completed : :published,
    started_at:  i < 5 ? (week.start_date + 3.days).to_datetime + 8.hours : nil,
    finished_at: i < 5 ? (week.start_date + 3.days).to_datetime + 9.hours + 5.minutes : nil,
    exercicios: [
      { name: "Terra Sumô", obs: nil, coach_comment: nil, video_link: nil,
        sections: [{ series: 3, reps: 12, carga: 50.0, rpe: 7.0, load_unit: "kg", feito: i < 5, actual_load: i < 5 ? 50.0 : nil, actual_rpe: i < 5 ? 7.0 : nil }] },
      { name: "Remada Unilateral", obs: nil, coach_comment: nil, video_link: nil,
        sections: [{ series: 3, reps: 12, carga: 20.0, rpe: 6.5, load_unit: "kg", feito: i < 5, actual_load: i < 5 ? 20.0 : nil, actual_rpe: i < 5 ? 6.5 : nil }] }
    ]
  )

  # Feedbacks das semanas concluídas
  if i < 5
    WeeklyFeedback.find_or_create_by!(week: week, aluno: beatriz[:aluno]) do |fb|
      fb.sleep_level        = [3, 4, 3, 4, 5][i]
      fb.stress_level       = [3, 2, 4, 2, 1][i]
      fb.diet_level         = [3, 3, 4, 4, 4][i]
      fb.body_weight        = [55.0, 54.8, 54.5, 54.2, 54.0][i]
      fb.training_desire    = [3, 4, 4, 5, 5][i]
      fb.general_evaluation = [
        "Primeira semana, me acostumando com a rotina.",
        "Melhorei bastante no agachamento. Me sinto mais forte.",
        "Semana estressante no trabalho, mas mantive os treinos.",
        "Muito boa semana! Perdi mais 300g e me sinto melhor.",
        "Última semana antes do deload, dei tudo! Resultado visível no espelho."
      ][i]
    end
  end
end

# =============================================================================
# NOTIFICAÇÕES
# =============================================================================
puts "🔔 Criando notificações..."

# Para Sarah (aluno)
sarah_treinos = sarah_block.weeks.includes(treinos: :exercicios).map(&:treinos).flatten

Notification.find_or_create_by!(user: sarah[:user], notification_type: :week_published, payload: {
  week_id: semanas_sarah[3].id, week_number: 4, coach_name: "Rafael Silva",
  block_title: "Especialização em Força — 8 semanas", route: "/aluno/treinos"
}) do |n|
  n.read_at = nil
end

Notification.find_or_create_by!(user: sarah[:user], notification_type: :feedback_form_available, payload: {
  week_id: semanas_sarah[2].id, week_number: 3, route: "/aluno/treinos"
}) do |n|
  n.read_at = 2.days.ago
end

# Para Rafael (coach) — notificações de treinos concluídos
completed_treinos = sarah_block.weeks.flat_map(&:treinos).select(&:completed?)

if completed_treinos.any?
  treino_ref = completed_treinos.last
  Notification.find_or_create_by!(user: rafael_user, notification_type: :workout_completed, payload: {
    treino_id: treino_ref.id, treino_name: treino_ref.name,
    aluno_name: "Sarah Mendes", aluno_id: sarah[:aluno].id,
    duration_seconds: 4800, exercicios: [], route: "/coach/treinos/#{sarah[:aluno].id}/#{treino_ref.id}"
  }) do |n|
    n.read_at = nil
  end
end

# Treino não realizado (Beatriz)
beat_treinos = beat_block.weeks.first.treinos
if beat_treinos.any?
  Notification.find_or_create_by!(user: rafael_user, notification_type: :workout_missed, payload: {
    treino_id: beat_treinos.first.id, treino_name: beat_treinos.first.name,
    aluno_name: "Beatriz Souza", aluno_id: beatriz[:aluno].id,
    route: "/coach/students/#{beatriz[:aluno].id}"
  }) do |n|
    n.read_at = 3.days.ago
  end
end

# Notificação de feedback pendente para coach
Notification.find_or_create_by!(user: rafael_user, notification_type: :feedback_overdue_coach_alert, payload: {
  aluno_name: "Gustavo Ferreira", aluno_id: gustavo[:aluno].id,
  week_number: 1, route: "/coach/students/#{gustavo[:aluno].id}"
}) do |n|
  n.read_at = nil
end

# =============================================================================
# ADMIN SETTINGS
# =============================================================================
puts "⚙️  Configurando admin settings..."
AdminSetting.instance.update!(push_enabled: true, emails_enabled: false)

# =============================================================================
# RESUMO FINAL
# =============================================================================
puts "\n✅ Seed concluído com sucesso!\n"
puts "=" * 60
puts "USUÁRIO PRINCIPAL DE TESTE:"
puts "  👤 Sarah Mendes"
puts "  📧 sarah@thegrinders.com"
puts "  🔑 #{SENHA}"
puts "  📍 Bloco atual: semana 4 de 8 (Especialização em Força)"
puts ""
puts "COACHES:"
puts "  📧 rafael@thegrinders.com  (#{SENHA})  — 15 alunos"
puts "  📧 marcos@thegrinders.com  (#{SENHA})  — sem alunos"
puts "  📧 camila@thegrinders.com  (#{SENHA})  — sem alunos"
puts ""
puts "ADMIN:"
puts "  📧 admin@thegrinders.com   (#{SENHA})"
puts ""
puts "ALUNOS COM BLOCOS:"
puts "  📧 sarah@thegrinders.com   — Bloco semana 4/8 (atual)"
puts "  📧 gustavo@thegrinders.com — Bloco semana 2/5 (atual)"
puts "  📧 beatriz@thegrinders.com — Bloco semana 6/6 (finalizando)"
puts ""
puts "TOTAIS:"
puts "  Users:          #{User.count}"
puts "  Alunos:         #{Aluno.count}"
puts "  Blocos:         #{TrainingBlock.count}"
puts "  Semanas:        #{Week.count}"
puts "  Treinos:        #{Treino.count}"
puts "  Exercícios:     #{Exercicio.count}"
puts "  Seções:         #{Section.count}"
puts "  Feedbacks:      #{WeeklyFeedback.count}"
puts "  Notificações:   #{Notification.count}"
puts "  Planos:         #{Plano.count}"
puts "  Pagamentos:     #{Pagamento.count}"
puts "  Assinaturas:    #{Assinatura.count}"
puts "  Exercise Models:#{ExerciseModel.count}"
puts "=" * 60

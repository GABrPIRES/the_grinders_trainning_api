# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_05_23_145949) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "admin_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "emails_enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "push_enabled", default: false, null: false
    t.boolean "ai_enabled_global", default: true, null: false
  end

  create_table "ai_load_suggestions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "section_id", null: false
    t.float "suggested_load", null: false
    t.integer "status", default: 0, null: false
    t.boolean "critical", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["section_id"], name: "index_ai_load_suggestions_on_section_id"
    t.index ["status"], name: "index_ai_load_suggestions_on_status"
  end

  create_table "alunos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.date "birth_date"
    t.float "weight"
    t.float "height"
    t.text "lesao"
    t.string "phone_number", null: false
    t.text "restricao_medica"
    t.text "objetivo"
    t.integer "treinos_semana"
    t.integer "tempo_treino"
    t.integer "horario_treino"
    t.integer "pr_supino"
    t.integer "pr_terra"
    t.integer "pr_agachamento"
    t.integer "new_pr_supino"
    t.integer "new_pr_terra"
    t.integer "new_pr_agachamento"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "personal_id", null: false
    t.index ["personal_id"], name: "index_alunos_on_personal_id"
    t.index ["user_id"], name: "index_alunos_on_user_id"
  end

  create_table "assinaturas", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "start_date", null: false
    t.datetime "end_date", null: false
    t.integer "status", default: 0, null: false
    t.uuid "aluno_id", null: false
    t.uuid "plano_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aluno_id"], name: "index_assinaturas_on_aluno_id"
    t.index ["plano_id"], name: "index_assinaturas_on_plano_id"
  end

  create_table "exercicios", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.uuid "treino_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "observation"
    t.text "coach_comment"
    t.text "video_link"
    t.integer "position", default: 0, null: false
    t.index ["treino_id", "position"], name: "index_exercicios_on_treino_id_and_position"
    t.index ["treino_id"], name: "index_exercicios_on_treino_id"
  end

  create_table "exercise_models", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "coach_id", null: false
    t.string "name", null: false
    t.string "exercise_name", null: false
    t.decimal "load", precision: 8, scale: 2
    t.string "load_unit", default: "kg"
    t.integer "series"
    t.string "reps"
    t.decimal "rpe", precision: 4, scale: 1
    t.text "coach_comment"
    t.text "video_link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coach_id"], name: "index_exercise_models_on_coach_id"
  end

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.integer "notification_type", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "pagamentos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.float "amount", null: false
    t.integer "status", default: 0, null: false
    t.datetime "due_date", null: false
    t.datetime "paid_at"
    t.uuid "aluno_id", null: false
    t.uuid "personal_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aluno_id"], name: "index_pagamentos_on_aluno_id"
    t.index ["personal_id"], name: "index_pagamentos_on_personal_id"
  end

  create_table "payment_methods", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "method_type", null: false
    t.jsonb "details", default: {}, null: false
    t.uuid "personal_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["personal_id"], name: "index_payment_methods_on_personal_id"
  end

  create_table "personals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.text "bio"
    t.string "phone_number"
    t.string "instagram"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "signup_code"
    t.datetime "signup_code_expires_at"
    t.boolean "auto_approve_students", default: false
    t.boolean "notifications_enabled", default: true, null: false
    t.boolean "email_on_workout_completed", default: true, null: false
    t.boolean "email_on_workout_missed", default: true, null: false
    t.boolean "email_students_on_publish", default: true, null: false
    t.boolean "ai_enabled_by_admin", default: true, null: false
    t.boolean "ai_enabled", default: true, null: false
    t.index ["ai_enabled_by_admin", "ai_enabled"], name: "index_personals_on_ai_enabled_by_admin_and_ai_enabled"
    t.index ["signup_code"], name: "index_personals_on_signup_code", unique: true
    t.index ["user_id"], name: "index_personals_on_user_id"
  end

  create_table "planos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.float "price", null: false
    t.integer "duration", null: false
    t.uuid "personal_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["personal_id"], name: "index_planos_on_personal_id"
  end

  create_table "push_subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "endpoint", null: false
    t.string "p256dh", null: false
    t.string "auth", null: false
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["endpoint"], name: "index_push_subscriptions_on_endpoint", unique: true
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "sections", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.float "carga"
    t.integer "series"
    t.integer "reps"
    t.string "equip"
    t.float "rpe"
    t.float "pr"
    t.boolean "feito", default: false
    t.uuid "exercicio_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "load_unit", default: "kg"
    t.float "actual_load"
    t.float "actual_rpe"
    t.index ["exercicio_id"], name: "index_sections_on_exercicio_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "training_blocks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.integer "weeks_duration", default: 5
    t.uuid "personal_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "aluno_id"
    t.index ["aluno_id"], name: "index_training_blocks_on_aluno_id"
    t.index ["personal_id"], name: "index_training_blocks_on_personal_id"
  end

  create_table "treinos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "day", null: false
    t.uuid "personal_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "week_id"
    t.integer "status", default: 1, null: false
    t.datetime "started_at"
    t.datetime "finished_at"
    t.text "ai_observation"
    t.datetime "missed_notified_at"
    t.boolean "created_by_ai", default: false, null: false
    t.index ["created_by_ai"], name: "index_treinos_on_created_by_ai"
    t.index ["personal_id"], name: "index_treinos_on_personal_id"
    t.index ["status"], name: "index_treinos_on_status"
    t.index ["week_id"], name: "index_treinos_on_week_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.string "verification_token"
    t.datetime "email_verified_at"
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["password_reset_token"], name: "index_users_on_password_reset_token", unique: true
    t.index ["verification_token"], name: "index_users_on_verification_token", unique: true
  end

  create_table "weekly_feedbacks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "week_id", null: false
    t.uuid "aluno_id", null: false
    t.integer "sleep_level"
    t.integer "stress_level"
    t.integer "diet_level"
    t.float "body_weight"
    t.integer "training_desire"
    t.text "general_evaluation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ai_status", default: 0, null: false
    t.text "ai_error_message"
    t.index ["ai_status"], name: "index_weekly_feedbacks_on_ai_status"
    t.index ["aluno_id"], name: "index_weekly_feedbacks_on_aluno_id"
    t.index ["week_id", "aluno_id"], name: "index_weekly_feedbacks_on_week_id_and_aluno_id", unique: true
    t.index ["week_id"], name: "index_weekly_feedbacks_on_week_id"
  end

  create_table "weeks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "week_number"
    t.uuid "training_block_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "periodization_goal", default: 1, null: false
    t.datetime "snoozed_at"
    t.datetime "coach_alerted_at"
    t.boolean "feedback_enabled", default: true, null: false
    t.datetime "expired_at"
    t.index ["periodization_goal"], name: "index_weeks_on_periodization_goal"
    t.index ["training_block_id", "expired_at"], name: "index_weeks_on_training_block_id_and_expired_at"
    t.index ["training_block_id"], name: "index_weeks_on_training_block_id"
  end

  add_foreign_key "ai_load_suggestions", "sections"
  add_foreign_key "alunos", "personals"
  add_foreign_key "alunos", "users"
  add_foreign_key "assinaturas", "alunos"
  add_foreign_key "assinaturas", "planos"
  add_foreign_key "exercicios", "treinos"
  add_foreign_key "exercise_models", "personals", column: "coach_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "pagamentos", "alunos"
  add_foreign_key "pagamentos", "personals"
  add_foreign_key "payment_methods", "personals"
  add_foreign_key "personals", "users"
  add_foreign_key "planos", "personals"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "sections", "exercicios"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "training_blocks", "alunos"
  add_foreign_key "training_blocks", "personals"
  add_foreign_key "treinos", "personals"
  add_foreign_key "treinos", "weeks"
  add_foreign_key "weekly_feedbacks", "alunos"
  add_foreign_key "weekly_feedbacks", "weeks"
  add_foreign_key "weeks", "training_blocks"
end

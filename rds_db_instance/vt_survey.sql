-- PostgresRds : 
-- database : SurveyManagement
-- username : postgres 
-- password : admin123

-- postgresql :
Use database vt_survey_management;

CREATE TABLE "users" (
  "user_id" VARCHAR(12) PRIMARY KEY,
  "salutation" VARCHAR(6),
  "first_name" VARCHAR(40),
  "middle_name" VARCHAR(40),
  "last_name" VARCHAR(40),
  "age" numeric,
  "gender" VARCHAR(8),
  "current_location" VARCHAR(100),
  "phone_number" numeric,
  "ethnicity" VARCHAR(20),
  "country_of_birth" VARCHAR(30),
  "email_id" VARCHAR(60),
  "specialization" VARCHAR(40)
);

CREATE TABLE "students" (
  "student_id" Varchar(12) PRIMARY KEY,
  "survey_id" Varchar(12),
  CONSTRAINT "FK_STUDENTS.student_id"
    FOREIGN KEY ("student_id")
      REFERENCES "users"("user_id")
);

CREATE TABLE "requesters" (
  "requester_id" VARCHAR(12) PRIMARY KEY,
  "survey_id" VARCHAR(12),
  "department_id" VARCHAR(12),
  CONSTRAINT "FK_requesters.requester_id"
    FOREIGN KEY ("requester_id")
      REFERENCES "users"("user_id"),
  CONSTRAINT "FK_requesters.survey_id"
    FOREIGN KEY ("survey_id")
      REFERENCES "students"("student_id")
);

CREATE TABLE "surveys" (
  "survey_id" Varchar(12) PRIMARY KEY,
  "survey_url" Varchar(12),
  "num_of_workers" numeric,
  "max_payment" Decimal(10,2),
  "created_timestamp" timestamp,
  "start_timestamp" TIMESTAMP ,
  "expiry_timestamp" TIMESTAMP,
  "remaining_fund" Decimal(10,2),
  "is_active" VARCHAR(8)
);

CREATE TABLE "workers" (
 "worker_id" Varchar(12) PRIMARY KEY,
  "survey_id" Varchar(12),
  "department_id" Varchar(12),
  CONSTRAINT "FK_workers.worker_id"
    FOREIGN KEY ("worker_id")
      REFERENCES "users"("user_id"),
  CONSTRAINT "FK_workers.survey_id"
    FOREIGN KEY ("survey_id")
      REFERENCES "surveys"("survey_id")
);

CREATE INDEX "worker_id" ON  "workers" ("worker_id");

CREATE INDEX "survey_id" ON  "workers" ("survey_id");



CREATE TABLE "admin" (
  "admin_id" Varchar(12) PRIMARY KEY,
  CONSTRAINT "FK_admin.admin_id"
    FOREIGN KEY ("admin_id")
      REFERENCES "users"("user_id")
);

CREATE TABLE "departments" (
  "department_id" Varchar(12) PRIMARY KEY,
  "dept_name"  Varchar(30)

);


CREATE INDEX "department_id" ON  "departments" ("department_id");

CREATE INDEX "dept_name" ON  "departments" ("department_id");

CREATE TABLE "credits_paid" (
  "survey_id" VARCHAR(12) PRIMARY KEY,
  "requester_id" VARCHAR(12),
  "student_id" VARCHAR(12),
  "credits" Decimal(10,2),
  "update_timestamp" TIMESTAMP,
  CONSTRAINT "FK_credits_paid.survey_id"
    FOREIGN KEY ("survey_id")
      REFERENCES "surveys"("survey_id"),
  CONSTRAINT "FK_credits_paid.student_id"
    FOREIGN KEY ("student_id")
      REFERENCES "students"("student_id")
);

CREATE TABLE "payments" (
	"payment_id" VARCHAR(12) PRIMARY KEY,
  "survey_id" Varchar(12)  ,
  "requester_id" Varchar(12),
  "worker_id" Varchar(12),
  "payment" Varchar(12),
  "update_timestamp" TIMESTAMP ,
  CONSTRAINT "FK_payments.requester_id"
    FOREIGN KEY ("requester_id")
      REFERENCES "requesters"("requester_id"),
  CONSTRAINT "FK_payments.survey_id"
    FOREIGN KEY ("survey_id")
      REFERENCES "surveys"("survey_id"),
  CONSTRAINT "FK_payments.worker_id"
    FOREIGN KEY ("worker_id")
      REFERENCES "workers"("worker_id")
);


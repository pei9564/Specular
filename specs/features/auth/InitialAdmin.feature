# language: en

# -------------------------------------------------------------------------
# SPEC-KIT SYSTEM INSTRUCTION (DO NOT REMOVE)
# -------------------------------------------------------------------------
# Role: Senior Product Architect & QA Lead
# Type: COMMAND (State Change)
# Domain: auth
# DBML: @specs/db_schema/auth.dbml (@provisional)
# Dependencies: None
# -------------------------------------------------------------------------

@ready
Feature: InitialAdmin — 系統啟動時自動建立初始管理員帳號

  # Summary:
  # When the system starts for the first time (or when no admin account exists),
  # it must automatically create a default administrator account so that the
  # platform can be managed immediately without manual database intervention.
  #
  # Business Value:
  # - Enables zero-touch deployment: operators can start using the system immediately
  # - Eliminates the need for manual database seeding or migration scripts
  # - Ensures the system is always in a manageable state after startup
  #
  # Actors:
  # - System (automated process on startup)
  # - Operator (uses the created account to log in and manage the platform)
  #
  # Assumptions:
  # - The initial admin credentials are provided via environment configuration
  # - The default username is "admin" if not configured (DBML: users.username)
  # - The default email is "admin@localhost" if not configured (DBML: users.email)
  # - The password MUST be provided via environment configuration (no hardcoded default)
  # - The initial admin account has full system privileges (DBML: users.role = "super_admin")
  # - Password is stored as a one-way hash in users.password_hash; plaintext is never persisted
  # - The system checks for existing admin accounts before creating one (idempotent)
  # - Password must be at least 12 characters with uppercase, lowercase, digit, and special character
  # - All timestamps use UTC (DBML: users.created_at, users.updated_at as timestamptz)
  #
  # Success Criteria:
  # - Operators can log in with the initial admin account within 30 seconds of first system startup
  # - 100% of deployments result in a usable admin account without manual intervention
  # - Repeated system restarts never produce duplicate admin accounts
  # - Systems without a configured password refuse to create insecure accounts and report the issue clearly
  #
  # Scope:
  # - In Scope: Automatic creation of one initial admin account on first startup
  # - Out of Scope: Admin account management UI, password reset flow, multi-admin seeding
  #
  # System Exit Strategy: Fail-fast. The system MUST abort startup with a clear
  # error message if initial admin creation fails (missing password, weak password,
  # or any other creation failure). The platform cannot be managed without an admin
  # account, so starting in a degraded state is not acceptable.
  #
  # Clarifications:
  # ### Session 2026-02-12
  # - Q: Should the system abort startup or continue without admin if creation fails? → A: Fail-fast (abort startup)
  # - Q: What is the default email when not configured? → A: Fixed default "admin@localhost"

  Background:
    Given the system is starting up
    And admin account configuration is available from the environment
    And the following system state applies:
      | entity | field         | value       | source          |
      | users  | username      | admin       | auth.dbml @prov |
      | users  | email         | (from env)  | auth.dbml @prov |
      | users  | password_hash | (from env)  | auth.dbml @prov |
      | users  | role          | super_admin | auth.dbml @prov |
      | users  | is_active     | true        | auth.dbml @prov |

  # =========================================================================
  # BLOCK A: COMMAND (Create Initial Admin)
  # =========================================================================

  Rule: [Precondition] 初始管理員只能在無管理員帳號且設定完整時建立

    Scenario: [Failure] 當已存在管理員帳號時，不應重複建立
      Given a record in "users" exists with:
        | field   | value       |
        | role    | super_admin |
      When the system executes the initial admin creation process
      Then no new record should be created in "users"
      And the existing record should remain unchanged

    Scenario: [Failure] 當密碼未透過環境設定提供時，系統應中止啟動
      Given no record in "users" exists with role "super_admin"
      And the environment variable for admin password is not set
      When the system executes the initial admin creation process
      Then the system should abort startup
      And the error message should indicate "Initial admin password must be provided via environment configuration"

    @auto_generated
    Scenario Outline: [Failure] 當密碼不符合 <rule> 時，建立應失敗
      Given no record in "users" exists with role "super_admin"
      And the configured admin password is "<invalid_password>"
      When the system executes the initial admin creation process
      Then the system should abort startup
      And the error message should indicate "<reason>"

      Examples:
        | rule               | invalid_password      | reason                                  |
        | 長度不足           | Sh0rt!                | Password must be at least 12 characters  |
        | 缺少大寫字母       | alllowercase1!specia  | Password must contain an uppercase letter |
        | 缺少小寫字母       | ALLUPPERCASE1!SPECIA  | Password must contain a lowercase letter  |
        | 缺少數字           | AllLettersOnly!Spec   | Password must contain a digit             |
        | 缺少特殊字元       | AllLettersAndDigit12  | Password must contain a special character |

    @auto_generated
    Scenario: [Failure] 當 username 與既有帳號重複時，建立應失敗
      Given a record in "users" exists with:
        | field    | value  |
        | username | admin  |
        | role     | member |
      And no record in "users" exists with role "super_admin"
      When the system executes the initial admin creation process with username "admin"
      Then the system should abort startup
      And the error message should indicate "Username already exists"

    @auto_generated
    Scenario: [Failure] 當 email 與既有帳號重複時，建立應失敗
      Given a record in "users" exists with:
        | field | value                |
        | email | admin@specular.local |
        | role  | member               |
      And no record in "users" exists with role "super_admin"
      When the system executes the initial admin creation process with email "admin@specular.local"
      Then the system should abort startup
      And the error message should indicate "Email already exists"

  Rule: [Postcondition] 成功建立後系統應有可用的管理員帳號

    Scenario: [Success] 當系統首次啟動且無管理員帳號時，應自動建立初始管理員
      Given no record in "users" exists with role "super_admin"
      And the environment provides the following admin configuration:
        | field    | value                |
        | username | admin                |
        | email    | admin@specular.local |
        | password | Str0ng!P@ssw0rd#2026 |
      When the system executes the initial admin creation process
      Then a new record in "users" should be created with:
        | field     | value                |
        | username  | admin                |
        | email     | admin@specular.local |
        | role      | super_admin          |
        | is_active | true                 |
      And the field "password_hash" should be a secure one-way hash (not equal to plaintext)
      And the field "created_at" should be a UTC timestamp

    Scenario: [Success] 當環境未設定 username 時，應使用預設值 "admin"
      Given no record in "users" exists with role "super_admin"
      And the environment provides only the admin password "V@lid!Passw0rd99"
      And the environment does not provide a username
      When the system executes the initial admin creation process
      Then a new record in "users" should be created with:
        | field    | value |
        | username | admin |

    Scenario: [Success] 當環境未設定 email 時，應使用預設值 "admin@localhost"
      Given no record in "users" exists with role "super_admin"
      And the environment provides only the admin password "V@lid!Passw0rd99"
      And the environment does not provide an email
      When the system executes the initial admin creation process
      Then a new record in "users" should be created with:
        | field | value           |
        | email | admin@localhost |

    Scenario: [Success] 重複啟動系統應保持冪等性
      Given a record in "users" exists with:
        | field     | value                |
        | username  | admin                |
        | role      | super_admin          |
        | is_active | true                 |
      When the system executes the initial admin creation process
      Then no new record should be created in "users"
      And the existing record should remain unchanged
      And the field "updated_at" should not be modified

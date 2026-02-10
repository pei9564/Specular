# language: en
@wip
Feature: [FEATURE NAME]
  As a [User Role]
  I want to [Action]
  So that [Benefit/Value]

  # Constitution Rule I: This file is the Single Source of Truth.
  # Constitution Rule IV: Scenarios implying external calls must be mockable.

  Background:
    Given the following initial state:
      | entity | status |
      | user   | active |
      # (Add strictly necessary background data)

  Rule: [Business Rule 1 - e.g., Valid Inputs]
    
    Scenario: [Happy Path Scenario Name]
      Given [Context]
      When [Action]
      Then [Expected Outcome]
      And [Database/State Effect]

    Scenario Outline: [Data Variations]
      Given input is "<input>"
      When processed
      Then result is "<result>"

      Examples:
        | input | result |
        | A     | OK     |
        | B     | OK     |

  Rule: [Business Rule 2 - e.g., Error Handling / Edge Cases]
    
    Scenario: [Sad Path - e.g., Resource Not Found]
      Given [Context with missing resource]
      When [Action]
      Then I should receive a "404 Not Found" error
      And no data should be persisted

    Scenario: [Sad Path - e.g., External Service Failure]
      # Remember Rule IV: Las Vegas Rule (Mocking)
      Given the external "PaymentGateway" is down
      When [Action]
      Then I should receive a "Service Unavailable" error
      And the transaction should be rolled back

  # Add more Rules and Scenarios as needed based on the user request.
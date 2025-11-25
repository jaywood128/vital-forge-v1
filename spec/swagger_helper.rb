# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  # Specify a root directory where Swagger JSON files are generated
  # NOTE: If you're using rswag-api to expose the generated Swagger as JSON,
  # then set this to a directory within the Rails.root that's served by the
  # web server
  config.swagger_root = Rails.root.join("swagger").to_s

  # Define one or more Swagger documents and provide global metadata for each
  config.swagger_docs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "VitalForge API V1",
        version: "v1",
        description: "VitalForge Fitness Tracking Application API - Authentication and User Management",
        contact: {
          name: "VitalForge Team",
          email: "support@vitalforge.com"
        }
      },
      paths: {},
      servers: [
        {
          url: "http://localhost:3000",
          description: "Development server"
        },
        {
          url: "https://api.vitalforge.com",
          description: "Production server"
        }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: "JWT",
            description: "JWT token for mobile authentication. Format: Bearer <token>"
          },
          csrf_token: {
            type: :apiKey,
            name: "X-CSRF-Token",
            in: :header,
            description: "CSRF protection token (required for web POST/PUT/DELETE)"
          },
          session_cookie: {
            type: :apiKey,
            name: "Cookie",
            in: :header,
            description: "Session cookie (automatically set after web login)"
          }
        },
        schemas: {
          User: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              email: { type: :string, format: :email, example: "john.doe@example.com" },
              first_name: { type: :string, example: "John" },
              last_name: { type: :string, example: "Doe" },
              full_name: { type: :string, example: "John Doe" },
              created_at: { type: :string, format: :"date-time" },
              updated_at: { type: :string, format: :"date-time" }
            },
            required: [ "id", "email" ]
          },
          UserRegistration: {
            type: :object,
            properties: {
              email: { type: :string, format: :email, example: "john.doe@example.com" },
              password: { type: :string, format: :password, example: "SecurePass123!" },
              password_confirmation: { type: :string, format: :password, example: "SecurePass123!" },
              first_name: { type: :string, example: "John" },
              last_name: { type: :string, example: "Doe" }
            },
            required: [ "email", "password", "password_confirmation", "first_name", "last_name" ]
          },
          LoginCredentials: {
            type: :object,
            properties: {
              email: { type: :string, format: :email, example: "john.doe@example.com" },
              password: { type: :string, format: :password, example: "SecurePass123!" }
            },
            required: [ "email", "password" ]
          },
          Error: {
            type: :object,
            properties: {
              error: { type: :string, example: "Invalid email or password" }
            }
          },
          ValidationErrors: {
            type: :object,
            properties: {
              errors: {
                type: :object,
                additionalProperties: {
                  type: :array,
                  items: { type: :string }
                },
                example: {
                  email: [ "can't be blank", "is invalid" ],
                  password: [ "is too short (minimum is 8 characters)" ]
                }
              }
            }
          },
          SuccessMessage: {
            type: :object,
            properties: {
              message: { type: :string, example: "Successfully logged out" }
            }
          }
        }
      },
      tags: [
        {
          name: "Authentication",
          description: "User authentication operations (login, logout, signup)"
        },
        {
          name: "Users",
          description: "User account management operations"
        }
      ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'
  # The swagger_docs configuration option has the filename, and format in
  # the key, this may want to be changed to avoid putting yaml in json files
  config.swagger_format = :yaml
end


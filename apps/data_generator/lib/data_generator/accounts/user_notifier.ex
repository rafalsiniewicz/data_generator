defmodule DataGenerator.Accounts.UserNotifier do
  @moduledoc """
  Composes and delivers email notifications for user account events.

  In development, emails are stored locally and viewable at `/dev/mailbox`.
  In test, emails are captured by `Swoosh.Adapters.Test` for assertions.
  In production, configure a real adapter in `config/runtime.exs`.
  """

  import Swoosh.Email

  alias DataGenerator.Mailer

  @from {"Data Generator", "noreply@datagenerator.app"}

  defp deliver(email) do
    Mailer.deliver(email)
  end

  @doc """
  Delivers email confirmation instructions to the given user.
  """
  def deliver_confirmation_instructions(user, url) do
    new()
    |> to({user.login, user.email})
    |> from(@from)
    |> subject("Confirm your email address")
    |> html_body("""
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px;">
      <h2 style="color: #1f2937; margin-bottom: 16px;">Welcome to Data Generator!</h2>
      <p style="color: #4b5563; font-size: 16px; line-height: 1.6;">
        Hi #{user.login},
      </p>
      <p style="color: #4b5563; font-size: 16px; line-height: 1.6;">
        Please confirm your email address by clicking the button below:
      </p>
      <div style="text-align: center; margin: 32px 0;">
        <a href="#{url}"
           style="background-color: #3b82f6; color: #ffffff; padding: 12px 32px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 16px; display: inline-block;">
          Confirm Email
        </a>
      </div>
      <p style="color: #6b7280; font-size: 14px; line-height: 1.6;">
        If the button doesn't work, copy and paste this link into your browser:
      </p>
      <p style="color: #3b82f6; font-size: 14px; word-break: break-all;">
        #{url}
      </p>
      <p style="color: #9ca3af; font-size: 12px; margin-top: 32px;">
        If you didn't create an account, you can safely ignore this email.
        This link will expire in 24 hours.
      </p>
    </div>
    """)
    |> text_body("""
    Welcome to Data Generator!

    Hi #{user.login},

    Please confirm your email address by visiting the link below:

    #{url}

    If you didn't create an account, you can safely ignore this email.
    This link will expire in 24 hours.
    """)
    |> deliver()
  end

  @doc """
  Delivers password reset instructions to the given user.
  """
  def deliver_password_reset_instructions(user, url) do
    new()
    |> to({user.login, user.email})
    |> from(@from)
    |> subject("Reset your password")
    |> html_body("""
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px;">
      <h2 style="color: #1f2937; margin-bottom: 16px;">Password Reset</h2>
      <p style="color: #4b5563; font-size: 16px; line-height: 1.6;">
        Hi #{user.login},
      </p>
      <p style="color: #4b5563; font-size: 16px; line-height: 1.6;">
        We received a request to reset your password. Click the button below to choose a new one:
      </p>
      <div style="text-align: center; margin: 32px 0;">
        <a href="#{url}"
           style="background-color: #3b82f6; color: #ffffff; padding: 12px 32px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 16px; display: inline-block;">
          Reset Password
        </a>
      </div>
      <p style="color: #6b7280; font-size: 14px; line-height: 1.6;">
        If the button doesn't work, copy and paste this link into your browser:
      </p>
      <p style="color: #3b82f6; font-size: 14px; word-break: break-all;">
        #{url}
      </p>
      <p style="color: #9ca3af; font-size: 12px; margin-top: 32px;">
        If you didn't request a password reset, you can safely ignore this email.
        This link will expire in 24 hours.
      </p>
    </div>
    """)
    |> text_body("""
    Password Reset

    Hi #{user.login},

    We received a request to reset your password.
    Visit the link below to choose a new one:

    #{url}

    If you didn't request a password reset, you can safely ignore this email.
    This link will expire in 24 hours.
    """)
    |> deliver()
  end
end

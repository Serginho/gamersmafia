# -*- encoding : utf-8 -*-
Rails.application.config.middleware.use ExceptionNotifier,
    :email_prefix => "[GM Error] ",
    :sender_address => %{"nagato" <nagato@gamersmafia.com>},
    :exception_recipients => [App.webmaster_email],
    :ignore_crawlers      => %w{Googlebot googlebot bingbot}

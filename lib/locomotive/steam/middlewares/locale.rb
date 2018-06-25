module Locomotive::Steam
  module Middlewares

    # Set the locale from the path if possible or use the default one
    #
    # Examples:
    #
    #   /fr/index   => locale = :fr
    #   /fr/        => locale = :fr
    #   /index      => locale = :en (default one)
    #
    # The
    #
    class Locale < ThreadSafe

      include Helpers

      def _call
        session['locale'] = locale = extract_locale

        log "Detecting locale #{locale.upcase}"

        I18n.with_locale(locale) do
          self.next
        end
      end

      protected

      def extract_locale
        _locale = locale_from_params || locale_from_session || locale_from_header || default_locale
        _path   = request.path_info

        if _path =~ /^\/(#{site.locales.join('|')})+(\/|$)/
          _locale  = $1
          _path    = _path.gsub($1 + $2, '')

          # let the other middlewares that the locale was
          # extracted from the path.
          env['steam.locale_in_path'] = true
        end

        env['steam.path']   = _path
        env['steam.locale'] = services.locale = _locale
      end

      def locale_from_header
        request.accept_language.lazy
          .sort { |a, b| b[1] <=> a[1] }
          .map  { |lang, _| lang[0..1].to_sym }
          .find { |lang| locales.include?(lang) }
      end

      def locale_from_session
        session['locale']&.to_sym
      end

      def locale_from_params
        params[:locale] && locales.include?(params[:locale].to_sym) ? params[:locale].to_sym : nil
      end

    end
  end
end

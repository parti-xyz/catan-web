require 'pathname'

module Catan
  class Avatar
    # BACKGROUND_COLORS = [
    #     "#ff4040", "#7f2020", "#cc5c33", "#734939", "#bf9c8f", "#995200",
    #     "#4c2900", "#f2a200", "#ffd580", "#332b1a", "#4c3d00", "#ffee00",
    #     "#b0b386", "#64664d", "#6c8020", "#c3d96c", "#143300", "#19bf00",
    #     "#53a669", "#bfffd9", "#40ffbf", "#1a332e", "#00b3a7", "#165955",
    #     "#00b8e6", "#69818c", "#005ce6", "#6086bf", "#000e66", "#202440",
    #     "#393973", "#4700b3", "#2b0d33", "#aa86b3", "#ee00ff", "#bf60b9",
    #     "#4d3949", "#ff00aa", "#7f0044", "#f20061", "#330007", "#d96c7b"
    #   ].freeze

    class << self
      def generate_avatar(text)
        text = initials(text.to_s.gsub(/[^\wㄱ-ㅎ가-힣 ]/,'').strip).upcase
        result = generate_image(text)
        Base64.encode64(result) if result.present?
      end

      private

      def fonts
        File.join root, 'assets/fonts'
      end

      def generate_image(text)
        return if text.blank?

        # background_color = BACKGROUND_COLORS.sample
        # black_contrast = LuminosityContrast.ratio(background_color[1..-1], '000')
        # white_contrast = LuminosityContrast.ratio(background_color[1..-1], 'fff')
        # font_color = black_contrast > white_contrast ? 'black' : 'white';
        background_color = "#0052cd";
        font_color = 'white';
        MiniMagick::Tool::Convert.new do |i|
          i.size("200x200")
          i.gravity("center")
          i.background(background_color)
          i.fill(font_color)
          i.pointsize("80")
          i.font(Rails.root.join("app/assets/fonts/NotoSansCJKkr-Regular.otf"))
          i.label(text)
          i.borderColor(background_color)
          i.border("50x50")
          i << "PNG:-"
        end
      end

      def initials(text)
        result = if text.include?(" ")
          initials_for_separator(text, " ")
        else
          initials_for_separator(text, ".")
        end

        if result.length < 2
          result + (text[1] || 0)
        else
          result[0..1]
        end
      end

      def initials_for_separator(text, separator)
        if text.include?(separator)
          text.split(separator).compact.map{|part| part[0]}.join
        else
          text[0] || ''
        end
      end
    end
  end
end

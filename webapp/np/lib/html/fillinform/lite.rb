require 'ext/object/blank'

module HTML
  module FillinForm
    class Lite
      @@form     = %q{[fF][oO][rR][mM]}
      @@input    = %q{[iI][nN][pP][uU][tT]}
      @@select   = %q{[sS][eE][lL][eE][cC][tT]}
      @@option   = %q{[oO][pP][tT][iI][oO][nN]}
      @@textarea = %q{[tT][eE][xX][tT][aA][rR][eE][aA]}

      @@checked  = %q{[cC][hH][eE][cC][kK][eE][dD]}
      @@selected = %q{[sS][eE][lL][eE][cC][tT][eE][dD]}
      @@multiple = %q{[mM][uU][lL][tT][iI][pP][lL][eE]}

      @@id    = %q{[iI][dD]}
      @@type  = %q{[tT][yY][pP][eE]}
      @@name  = %q{[nN][aA][mM][eE]}
      @@value = %q{[vV][aA][lL][uU][eE]}

      SPACE      = %q{\s}
      ATTR_NAME  = %q{[\w\-]+}
      ATTR_VALUE = %q{(?:"[^"]*"|'[^']*'|[^'"/>\s]+|[\w\-]+)}
      ATTR       = %Q{(?:#{SPACE}+(?:#{ATTR_NAME}(?:=#{ATTR_VALUE})?))}

      FORM     = %Q{(?:<#{@@form}#{ATTR}+#{SPACE}*>)}
      INPUT    = %Q{(?:<#{@@input}#{ATTR}+#{SPACE}*/?>)}
      SELECT   = %Q{(?:<#{@@select}#{ATTR}+#{SPACE}*>)}
      OPTION   = %Q{(?:<#{@@option}#{ATTR}*#{SPACE}*>)}
      TEXTAREA = %Q{(?:<#{@@textarea}#{ATTR}+#{SPACE}*>)}

      END_FORM     = %Q{(?:</#{@@form}>)}
      END_SELECT   = %Q{(?:</#{@@select}>)}
      END_OPTION   = %Q{(?:</#{@@option}>)}
      END_TEXTAREA = %Q{(?:</#{@@textarea}>)}

      CHECKED  = %Q{(?:#{@@checked}(?:=(?:"#{@@checked}"|'#{@@checked}'|#{@@checked}))?)}
      SELECTED = %Q{(?:#{@@selected}(?:=(?:"#{@@selected}"|'#{@@selected}'|#{@@selected}))?)}
      MULTIPLE = %Q{(?:#{@@multiple}(?:=(?:"#{@@multiple}"|'#{@@multiple}'|#{@@multiple}))?)}

      def _unquote(str)
        str.match(/(['"])(.*)\1/mx)[2] rescue str
      end

      def _get_id(tag)
        matched = tag.match(/#{@@id}=(#{ATTR_VALUE})/mx)[1] rescue nil
        _unquote(matched)
      end

      def _get_type(tag)
        matched = tag.match(/#{@@type}=(#{ATTR_VALUE})/mx)[1] rescue nil
        _unquote(matched)
      end

      def _get_name(tag)
        matched = tag.match(/#{@@name}=(#{ATTR_VALUE})/mx)[1] rescue nil
        _unquote(matched)
      end

      def _get_value(tag)
        matched = tag.match(/#{@@value}=(#{ATTR_VALUE})/mx)[1] rescue nil
        _unquote(matched)
      end

      attr_accessor :data, :params, :target, :ignore_types, :escape, :decode_entity, :layer

      def initialize(opt={})
        @params = {}
        @ignore_types = {
          'button'   => true,
          'submit'   => true,
          'reset'    => true,
          'password' => true,
          'image'    => true,
          'file'     => true,
        }
        @escape        = method(:_escape_html)
        @decode_entity = method(:_noop)
        @layer         = ''

        self._parse_option(opt)
      end

      # simply, not support options for first implementation
      def _parse_option(opt={})
        return self if opt.blank?

        self
      end

      def fill(src, q, opt={})
        context = self._parse_option(opt)

        content = nil
        if src.is_a?(String)
          content = src.clone
        elsif src.is_a?(Array)
          content = src.join('')
        else
          # TODO: support file handle
        end

        context.data = _to_form_object(q)

        if context.target.present?
          # TODO
        else
          _fill(context, content)
        end
      end

      def _fill(context, content)
        content.gsub!(/(#{INPUT})/mx) do
          _fill_input(context, Regexp.last_match[1]).to_s
        end

        content.gsub!(/(#{SELECT})(.*?)(#{END_SELECT})/mx) do
          tag, inner, tag_end = Regexp.last_match[1, 3]
          tag + _fill_select(context, tag, inner).to_s + tag_end
        end

        content.gsub!(/(#{TEXTAREA})(.*?)(#{END_TEXTAREA})/mx) do
          tag, inner, tag_end = Regexp.last_match[1, 3]
          tag + _fill_textarea(context, tag, inner).to_s + tag_end
        end

        content
      end

      def _fill_input(context, tag)
        type = _get_type(tag) || 'text'
        if @ignore_types[type].present?
          return tag
        end

        value_ref = context._get_param(_get_name(tag))
        return tag if value_ref.blank?

        if type == 'checkbox' or type == 'radio'
          # TODO
        else
          new_value = context.escape.call(value_ref[0])

          tag.gsub!(/#{@@value}=#{ATTR_VALUE}/mx, %Q(value="#{new_value}")) or tag.gsub(%r|#{SPACE}*(/?)>\z|mx, %Q(value="#{new_value}")+'\1>')
        end

        tag
      end

      def _fill_select(context, tag, content)
        # TODO
      end

      def _fill_option(context, value_ref, tag, content)
        # TODO
      end

      def _fill_textarea(context, tag, content)
        values_ref = context._get_param(_get_name(tag))
        return content if values_ref.blank?

        context.escape.call(values_ref[0])
      end

      def _get_param(name)
        return if name.blank? or self.ignore_types[name]

        ref = self.params[name]

        if ref.blank?
          ref = self.params[name] = [self.data.params[name]]
        end

        ref
      end

      def _noop(s)
        s
      end

      def _escape_html(s)
        return '' if s.blank?

        s.gsub!(/&/, '&amp;')
        s.gsub!(/</, '&lt;')
        s.gsub!(/>/, '&gt;')
        s.gsub!(/"/, '&quot;')

        s
      end

      def _to_form_object(q)
        return q

        # TODO: Hash, Array, Procなどのwrap
      end
    end
  end
end

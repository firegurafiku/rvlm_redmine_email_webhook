module RvlmRedmineEmailWebhook

  class Configuration

    # @return [Hash<Symbol, Proc>] Registered hooks by hook name
    def self.hooks
      @hooks || {}
    end

    def self.load!(config_dir)

      hook_files = Dir.glob(
        File.join(config_dir, '*.hook.rb')
      )

      hooks = {}

      hook_files.each do |file|

        LogUtils.info "Evaluating hook configuration: #{file}"

        begin
          dsl = DSL.new
          dsl.instance_eval(File.read(file), file)

          dsl.registered_hooks.each_pair do |name, block|
            if hooks.key?(name)
              LogUtils.raise KeyError, "Duplicate hook name: #{name}, while loading #{file}"
            end

            LogUtils.info "Adding hook: #{name} from #{file}"
            hooks[name] = block
          end

        rescue => e
          LogUtils.error "Failed to load hook configuration from #{file}: #{e.class}: #{e.message}"
        end
      end

      @hooks = hooks.freeze
    end

    class DSL

      # TODO: Hide 'registered_hooks' from hook definitions.
      # name (Symbol) => Proc
      attr_reader :registered_hooks

      def initialize
        @registered_hooks = {}
      end

      # register_hook(:telegram) { |user, message| ... }
      def register_hook(name, &block)
        raise ArgumentError, "Hook name must be a Symbol" unless name.is_a?(Symbol)
        raise ArgumentError, "register_hook(:#{name}) requires a block" unless block_given?

        @registered_hooks[name] = block
      end
    end
  end
end

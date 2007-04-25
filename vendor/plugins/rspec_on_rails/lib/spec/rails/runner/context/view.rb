module Spec
  module Rails
    module Runner
      class ViewEvalContext < Spec::Rails::Runner::FunctionalEvalContext

        def setup #:nodoc:
          super
          # these go here so that flash and session work as they should.
          @controller.send :initialize_template_class, @response
          @controller.send :assign_shortcuts, @request, @response rescue nil
          @session = @controller.session
          @controller.class.send :public, :flash # make flash accessible to the spec
        end
      
        def teardown #:nodoc:
          super
          #necessary to ensure that base_view_path is not set across contexts
          ActionView::Base.base_view_path = nil
        end

        def set_base_view_path(options) #:nodoc:
          ActionView::Base.base_view_path = base_view_path(options)
        end

        def base_view_path(options) #:nodoc:
          "/#{derived_controller_name(options)}/"
        end

        def derived_controller_name(options) #:nodoc:
          parts = subject_of_render(options).split('/').reject { |part| part.empty? }
          "#{parts[0..-2].join('/')}"
        end
      
        def subject_of_render(options) #:nodoc:
          [:template, :partial, :file].each do |render_type|
            if options.has_key?(render_type)
              return options[render_type]
            end
          end
          raise Exception.new("Unhandled render type in view spec.")
        end
      
        def add_helpers(options) #:nodoc:
          @controller.add_helper("application")
          @controller.add_helper(derived_controller_name(options))
          @controller.add_helper(options[:helper]) if options[:helper]
          options[:helpers].each { |helper| @controller.add_helper(helper) } if options[:helpers]
        end

        # Renders a template for a View Spec, which then provides access to the result
        # through the +response+.
        # 
        # == Examples
        # 
        #   render('/people/list')
        #   render('/people/list', :helper => MyHelper)
        #   render('/people/list', :helpers => [MyHelper, MyOtherHelper])
        #   render(:partial => '/people/_address')
        #
        # See Spec::Rails::Runner::ViewContext for more information.
        def render(template=nil, options={})
          case template
          when Hash
            options = template
          when String || Symbol
            options[:template] = template.to_s
          end

          set_base_view_path(options)
          add_helpers(options)

          @action_name = action_name caller[0] if options.empty?
          assigns[:action_name] = @action_name

          @request.path_parameters = {
            :controller => @controller.controller_name,
            :action => @action_name,
          }

          defaults = { :layout => false }
          options = defaults.merge options
        
          @request.parameters.merge(@params)

          @controller.instance_variable_set :@params, @request.parameters
          @controller.send :initialize_current_url
          
          @controller.class.instance_eval %{
            def controller_path
              "#{derived_controller_name(options)}"
            end
          }

          # Rails 1.0
          @controller.send :assign_names rescue nil
          @controller.send :fire_flash rescue nil

          # Rails 1.1
          @controller.send :forget_variables_added_to_assigns rescue nil

          # Do the render
          @controller.render options

          # Rails 1.1
          @controller.send :process_cleanup rescue nil
        end
      end

      class ViewSpecController < ActionController::Base #:nodoc:
        attr_reader :template

        def add_helper_for(template_path)
          add_helper(template_path.split('/')[0])
        end

        def add_helper(name)
          begin
            helper_module = "#{name}_helper".camelize.constantize
          rescue
            return
          end
          (class << template; self; end).class_eval do
            include helper_module
          end
        end
      
      end
      
      # View Specs live in $RAILS_ROOT/spec/views/.
      #
      # View Specs use Spec::Rails::Runner::ViewContext,
      # which provides access to views without invoking any of your controllers.
      # See Spec::Rails::Expectations::Matchers for information about specific
      # expectations that you can set on views.
      #
      # == Example
      #
      #   context "login/login" do
      #     setup do
      #       render 'login/login'
      #     end
      # 
      #     specify "should display login form" do
      #       response.should have_tag("form[action=/login]") do
      #         with_tag("input[type=text][name=email]")
      #         with_tag("input[type=password][name=password]")
      #         with_tag("input[type=submit][value=Login]")
      #       end
      #     end
      #   end
      class ViewContext < Spec::Rails::Runner::Context
        def execution_context(specification=nil) # :nodoc:
          instance = execution_context_class.new(specification)
          instance.instance_eval { @controller_class_name = "Spec::Rails::Runner::ViewSpecController" }
          instance
        end
        def before_context_eval # :nodoc:
          inherit_context_eval_module_from Spec::Rails::Runner::ViewEvalContext
          @context_eval_module.init_global_fixtures
        end
      end
    end
  end
end

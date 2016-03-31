RSpec.describe StackMaster::TemplateCompiler do
  describe '.compile' do
    let(:config) { double(template_compilers: { fab: :test_template_compiler }) }
    let(:template_file_path) { '/base_dir/templates/template.fab' }

    class TestTemplateCompiler
      def self.compile(template_file_path); end
    end

    context 'when a template compiler is registered for the given file type' do
      before {
        StackMaster::TemplateCompiler.register(:test_template_compiler, TestTemplateCompiler)
      }

      it 'compiles the template using the relevant template compiler' do
        expect(TestTemplateCompiler).to receive(:compile).with(template_file_path)
        StackMaster::TemplateCompiler.compile(config, template_file_path)
      end
    end
  end
end

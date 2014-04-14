require 'fast_spec_helper'
require 'rubocop'
require 'active_support/core_ext/string/strip'
require 'app/models/style_guide'

describe StyleGuide, '#violations' do
  context 'with custom configuration' do
    it 'finds only one violation' do
      content = <<-EOL.strip_heredoc
        def test_method()
          "hello world"
        end
      EOL
      config = <<-EOL.strip_heredoc
        StringLiterals:
          EnforcedStyle: double_quotes
          Enabled: true
      EOL
      style_guide = StyleGuide.new(config)

      violations = style_guide.violations(content)

      expect(violations.map(&:message)).to eq [
        "Omit the parentheses in defs when the method doesn't accept any arguments."
      ]
    end
  end

  context 'with default configuration' do
    describe 'line character limit' do
      it 'does not have violation' do
        expect(violations_in('a' * 80)).to be_empty
      end

      it 'has violation' do
        expect(violations_in('a' * 81)).to eq ['Line is too long. [81/80]']
      end
    end

    describe 'trailing white space' do
      it 'does not have violation' do
        expect(violations_in('def some_method')).to be_empty
      end

      it 'has violation' do
        expect(violations_in('def some_method   ')).
          to eq ['Trailing whitespace detected.']
      end
    end

    describe 'parentheses white space' do
      it 'does not have violation' do
        expect(violations_in('some_method(1)')).to be_empty
      end

      it 'has violation' do
        expect(violations_in('some_method( 1)')).
          to eq ['Space inside parentheses detected.']
      end
    end

    describe 'square brackets white space' do
      it 'does not have violation' do
        content = <<-EOL.strip_heredoc
          def hello
            true
          end
        EOL

        expect(violations_in('[1, 2]')).to be_empty
      end

      it 'has violation' do
        expect(violations_in('[1, 2 ]')).
          to eq ['Space inside square brackets detected.']
      end
    end

    describe 'curly brackets white space' do
      it 'does not have violation' do
        expect(violations_in('{ a: 1, b: 2 }')).to be_empty
      end

      it 'has violation' do
        expect(violations_in('{a: 1, b: 2}')).
          to eq ['Space inside { missing.', 'Space inside } missing.']
      end
    end

    describe 'curly brackets and pipe white space' do
      it 'does not have violation' do
        expect(violations_in('ary.map { |a| a.something }')).to  be_empty
      end

      it 'has violation' do
        expect(violations_in('ary.map{|a| a.something}')).  to eq [
          'Space missing to the left of {.',
          'Space between { and | missing.',
          'Space missing inside }.'
        ]
      end
    end

    describe 'inline comments' do
      it 'does not have a violation' do
        pending
        expect(violations_in('def foo # bad method')).to eq [
          'Avoid inline comments'
        ]
      end
    end

    describe 'comma white space' do
      it 'does not have violation' do
        expect(violations_in('def foobar(a, b, c)')).to be_empty
      end

      it 'has violation' do
        expect(violations_in('def foobar(a,b,c)')).to eq [
          'Space missing after comma.',
          'Space missing after comma.'
        ]
      end
    end

    describe 'semicolon white space' do
      it 'does not have violation' do
        expect(violations_in('class foo; bar; end')).to be_empty
      end

      it 'has violation' do
        expect(violations_in('class foo;bar; end')).to eq [
          'Space missing after semicolon.'
        ]
      end
    end

    describe 'colon white space' do
      it 'does not have violation' do
        expect(violations_in('admin? ? true : false')).to be_empty
      end

      it 'has violation' do
        expect(violations_in('admin? ? true: false')).to eq [
          "Surrounding space missing for operator ':'."
        ]
      end
    end

    describe 'multiline method chaining' do
      it 'does not have violation' do
        content = <<-CONTENT.strip_heredoc.gsub(/\n\Z/)
        foo.
          bar.
          baz
        CONTENT
        puts violations_in(content)
        expect(violations_in(content)).to be_empty
      end

      it 'has violation' do
        pending
        expect(violations_in("foo\n.bar\n.baz")).to eq [
          'For multiline method invocations, place the . at the end of each line'
        ]
      end
    end

    describe 'empty line between methods' do
      it 'does not have violation' do
        content = <<-CONTENT.strip_heredoc.gsub(/\n\Z/)
        def foo
          bar
        end

        def bar
          foo
        end
        CONTENT
        expect(violations_in(content)).to be_empty
      end

      it 'has violation' do
        expect(violations_in("def foo\n  bar\nend\ndef bar\n  foo\nend")).
          to eq ['Use empty lines between defs.']
      end
    end

    describe 'use new lines around multiline blocks' do
      it 'does not have violation' do
        expect(violations_in('things.each do\n  stuff\nend\n\nmore code')).
          to be_empty
      end

      it 'has violation' do
        pending
        expect(violations_in('things.each do\n  stuff\nend\nmore code')).to eq [
          'Use newlines around multi-line blocks'
        ]
      end
    end

    describe 'case for SQL statements' do
      it 'does not have violation' do
        expect(violations_in("SELECT * FROM 'users'")).to be_empty
      end

      it 'has violation' do
        pending
        expect(violations_in("select * FROM 'users'")).to eq [
          'Use uppercase for SQL key words and lowercase for SQL identifiers.'
        ]
      end
    end
  end

  private

  def violations_in(content)
    StyleGuide.new.violations("#{content}\n").map(&:message)
  end
end

# frozen_string_literal: true

# !!!!!! TODO !!!!!!!
# [!] Don't forget to create a Pull Request on https://gitlab.com/danger-systems/danger.systems/raw/master/plugins-search-generated.json
#  to add your plugin to the plugins.json file once it is released!

module Danger
  # Checks for circumvention of RuboCop via `rubocop:disabe` and links
  # to documentation of the rule for each one (if there is any).
  #
  # @example Check for usage of `rubocop:disable` for added lines
  # ```rb
  # rubocop_disable_checker.run(
  #   ignore_paths: ["Dangerfile", "gems/"],
  #   message: "Please don't disable RuboCop unless absolutely necessary!",
  #   tag_reviewers: ["yourgithubteamhandle"]
  # )
  # ```
  #
  # @see  jaredsmithse/danger-rubocop_disable_checker
  # @tags ruby, rubocop, linter
  #
  class DangerRubocopDisableChecker < Plugin
    EMPTY_CONFIG = {}.freeze

    COMMENT = <<~COMMENT.gsub("\n", " ")
      Disabling a rule is usually an indication of a code smell and can be easily avoided.
      If you feel this is an exceptional case, please add a comment above with justification.
    COMMENT

    IGNORE_PATHS = ["Dangerfile"].freeze

    # An attribute that you can read/write from your Dangerfile
    #
    # @return   [Array<String>]
    attr_reader :ignore_paths

    # An attribute that you can read/write from your Dangerfile
    #
    # @return   [String]
    attr_reader :message

    # If there are disables, you can optionally tag teammates
    #
    # @return   [Array<String>]
    attr_reader :tag_reviewers

    # A method that you can call from your Dangerfile
    # @param config [Hash] configuration options when running the checker
    # @return   [void]
    def run(config = EMPTY_CONFIG)
      @ignore_paths = config.fetch(:ignore_paths, IGNORE_PATHS)
      @message = config.fetch(:message, COMMENT)
      @tag_reviewers = config.fetch(:tag_reviewers, [])

      disable_violations = violations(file_diffs(git.diff))
      inline_comments(disable_violations)
      pr_comment if disable_violations.any?
    end

    private

    def inline_comments(disable_violations)
      disable_violations.each do |violation|
        warn(inline_format(violation[:disabled_cops]), violation.slice(:file, :line))
      end
    end

    def pr_comment
      reviewers = tag_reviewers.map { |reviewer| "@#{reviewer}"}.join(", ")
      warn("Detected use of `rubocop:disable` directive. cc #{reviewers}")
    end

    def inline_format(cops)
      disable_comment =
        if cops.none?
          "Detected `rubocop:disable`"
        elsif cops.one?
          "Detected `rubocop:disable` for #{cops.first}"
        else
          cops.map! { |cop| "- #{cop}" }
          "Detected `rubocop:disable` for the following cops: \n #{cops.join("\n")}"
        end

      <<~COMMENT
        #{disable_comment}\n\n
        > **Note**
        > #{message}
      COMMENT
    end

    def violations(diffs)
      diffs.flat_map do |file, insertions|
        insertions
          .select { |line| line[:content].include?("# rubocop:disable") }
          .map do |line|
            {
              file: file,
              line: line[:line_number],
              disabled_cops: parse_cops(line[:content]),
            }
          end
      end
    end

    def parse_cops(line_content)
      match_data = line_content.match(/# rubocop:disable (?<cops>.*)/)
      return [] unless match_data

      match_data[:cops].split(",").map { |cop| add_url(cop.strip) }
    end

    def add_url(cop)
      doc_link = `bundle exec rubocop --show-docs-url #{cop}`.tr("\n", "")
      doc_link.empty? ? cop : "[#{cop}](#{doc_link})"
    end

    def file_diffs(git_diffs)
      git_diffs
        .select { |diff| ignore_paths.none? { |path| diff.path.include?(path) } }
        .each_with_object({}) do |diff, diff_obj|
          diff_obj[diff.path] = chunks_for_file(diff)
        end
    end

    def chunks_for_file(full_diff)
      full_diff
        .patch
        .split("\n@@")
        .tap(&:shift)
        .flat_map { |chunk| process_chunk(chunk) }
        .compact
    end

    def process_chunk(chunk)
      first_line, *diff = chunk.split("\n")
      line_number = first_line.match(/\+(\d+),?(\d?)/).captures.first.to_i

      diff.each_with_object([]) do |line, insertions|
        if line.start_with?("+")
          insertions << { content: line, line_number: line_number }
        end

        line_number += 1 unless line.start_with?("-")
      end
    end
  end
end

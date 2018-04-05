module Gitlab
  module Git
    class Checksum
      include Gitlab::Git::Popen

      EMPTY_REPOSITORY_CHECKSUM = '0000000000000000000000000000000000000000'.freeze

      Failure = Class.new(StandardError)

      attr_reader :path, :relative_path, :storage, :storage_path, :gl_repository

      def initialize(storage, relative_path, gl_repository)
        @storage       = storage
        @storage_path  = Gitlab.config.repositories.storages[storage].legacy_disk_path
        @relative_path = "#{relative_path}.git"
        @path          = File.join(storage_path, @relative_path)
        @gl_repository = gl_repository
      end

      def calculate
        unless repository_exists?
          failure!(Gitlab::Git::Repository::NoRepository, 'No repository for such path')
        end

        raw_repository.gitaly_migrate(:calculate_checksum) do |is_enabled|
          if is_enabled
            calculate_checksum_gitaly
          else
            calculate_checksum_by_shelling_out
          end
        end
      end

      private

      def repository_exists?
        raw_repository.exists?
      end

      def calculate_checksum_gitaly
        gitaly_repository_client.calculate_checksum
      end

      def calculate_checksum_by_shelling_out
        args = %W(--git-dir=#{path} show-ref --heads --tags)
        output, status = run_git(args)

        if status&.zero?
          refs = output.split("\n")

          result = refs.inject(nil) do |checksum, ref|
            value = Digest::SHA1.hexdigest(ref).hex

            if checksum.nil?
              value
            else
              checksum ^ value
            end
          end

          result.to_s(16)
        else
          # Empty repositories return with a non-zero status and an empty output.
          if output&.empty?
            EMPTY_REPOSITORY_CHECKSUM
          else
            failure!(Gitlab::Git::Checksum::Failure, output)
          end
        end
      end

      def failure!(klass, message)
        Gitlab::GitLogger.error("'git show-ref --heads --tags' in #{path}: #{message}")

        raise klass.new("Could not calculate the checksum for #{path}: #{message}")
      end

      def circuit_breaker
        @circuit_breaker ||= Gitlab::Git::Storage::CircuitBreaker.for_storage(storage)
      end

      def raw_repository
        @raw_repository ||= Gitlab::Git::Repository.new(storage, relative_path, gl_repository)
      end

      def gitaly_repository_client
        raw_repository.gitaly_repository_client
      end

      def run_git(args)
        circuit_breaker.perform do
          popen([Gitlab.config.git.bin_path, *args], path)
        end
      end
    end
  end
end

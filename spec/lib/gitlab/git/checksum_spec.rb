require 'spec_helper'

describe Gitlab::Git::Checksum, seed_helper: true do
  let(:storage) { 'default' }
  let(:gl_repository) { 'project-123' }

  shared_examples 'calculating checksum' do
    it 'raises Gitlab::Git::Repository::NoRepository when there is no repo' do
      checksum = described_class.new(storage, 'nonexistent-repo', gl_repository)

      expect { checksum.calculate }.to raise_error Gitlab::Git::Repository::NoRepository
    end

    it 'pretends that checksum is 000000... when the repo is empty' do
      FileUtils.rm_rf(File.join(SEED_STORAGE_PATH, 'empty-repo.git'))

      system(git_env, *%W(#{Gitlab.config.git.bin_path} init --bare empty-repo.git),
             chdir: SEED_STORAGE_PATH,
             out:   '/dev/null',
             err:   '/dev/null')

      checksum = described_class.new(storage, 'empty-repo', gl_repository)

      expect(checksum.calculate).to eq '0000000000000000000000000000000000000000'
    end

    it 'calculates the checksum when there is a repo' do
      checksum = described_class.new(storage, 'gitlab-git-test', gl_repository)

      expect(checksum.calculate).to eq '54f21be4c32c02f6788d72207fa03ad3bce725e4'
    end
  end

  context 'when calculate_checksum Gitaly feature is enabled' do
    it_behaves_like 'calculating checksum'
  end

  context 'when calculate_checksum Gitaly feature is disabled', :disable_gitaly do
    it_behaves_like 'calculating checksum'

    it "raises a Gitlab::Git::Repository::Failure error if the `popen` call to git returns a non-zero exit code" do
      checksum = described_class.new(storage, 'gitlab-git-test', gl_repository)

      allow(checksum).to receive(:popen).and_return(['output', nil])

      expect { checksum.calculate }.to raise_error Gitlab::Git::Checksum::Failure
    end
  end
end

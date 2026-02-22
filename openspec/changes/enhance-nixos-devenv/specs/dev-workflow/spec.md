# Development Workflow Capability

## ADDED Requirements

### Requirement: Automatic Development Environment Activation

The system SHALL automatically activate the appropriate development environment when entering a project directory.

#### Scenario: Directory entry activates environment

- **WHEN** a developer navigates to a project directory containing a `.envrc` file
- **THEN** direnv automatically loads the flake-based development shell
- **AND** all tools and dependencies specified in the flake become available
- **AND** environment variables are set according to the shellHook

#### Scenario: Directory exit deactivates environment

- **WHEN** a developer navigates away from a project directory
- **THEN** direnv automatically unloads the development environment
- **AND** the shell returns to the default user environment
- **AND** project-specific tools are no longer in PATH

#### Scenario: Environment changes are detected automatically

- **WHEN** the flake.nix or flake.lock file changes
- **THEN** direnv detects the change and prompts for re-evaluation
- **AND** the developer can reload with `direnv allow`
- **AND** nix-direnv caches the evaluation result for faster subsequent loads

### Requirement: Visual Build Progress Monitoring

The system SHALL provide visual feedback during Nix build and evaluation operations.

#### Scenario: Build progress is displayed graphically

- **WHEN** a developer runs a build command with nix-output-monitor (nom)
- **THEN** a visual progress bar shows build status
- **AND** individual derivation build times are displayed
- **AND** parallel builds are shown with hierarchical tree view
- **AND** warnings and errors are highlighted in color

#### Scenario: Long-running builds provide ETA

- **WHEN** a build operation takes longer than 10 seconds
- **THEN** nom displays an estimated time to completion
- **AND** shows percentage progress for each derivation
- **AND** updates the display in real-time

### Requirement: Code Quality Pre-commit Hooks

The system SHALL enforce code quality checks before commits are created.

#### Scenario: Pre-commit hooks run on staged changes

- **WHEN** a developer runs `git commit`
- **THEN** pre-commit hooks execute automatically on staged files
- **AND** nixpkgs-fmt formats all .nix files
- **AND** statix lints Nix code for anti-patterns
- **AND** deadnix detects unused Nix code
- **AND** the commit proceeds only if all checks pass

#### Scenario: Hooks can be bypassed when necessary

- **WHEN** a developer needs to commit without running hooks
- **THEN** they can use `git commit --no-verify`
- **AND** the commit is created without running pre-commit checks
- **AND** a warning is displayed about skipped checks

#### Scenario: Hooks can be run manually

- **WHEN** a developer runs `pre-commit run --all-files`
- **THEN** all configured hooks execute on all files in the repository
- **AND** results are displayed with file paths and line numbers
- **AND** auto-fixable issues are corrected automatically

### Requirement: Dependency Update Tracking

The system SHALL facilitate tracking and applying dependency updates.

#### Scenario: Flake inputs can be checked for updates

- **WHEN** a developer runs `nix flake update --dry-run`
- **THEN** available updates for all inputs are displayed
- **AND** version changes are shown (old → new)
- **AND** no changes are written to flake.lock

#### Scenario: Selective input updates

- **WHEN** a developer runs `nix flake lock --update-input nixpkgs`
- **THEN** only the specified input (nixpkgs) is updated
- **AND** other inputs remain at their current versions
- **AND** flake.lock is updated with the new version

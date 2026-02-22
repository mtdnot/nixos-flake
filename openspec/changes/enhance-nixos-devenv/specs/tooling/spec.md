# Development Tooling Capability

## ADDED Requirements

### Requirement: Nix Code Formatting

The system SHALL provide consistent code formatting for Nix expressions.

#### Scenario: Format single file

- **WHEN** a developer runs `nixpkgs-fmt file.nix`
- **THEN** the file is formatted according to nixpkgs conventions
- **AND** changes are written to the file in-place
- **AND** exit code 0 indicates successful formatting

#### Scenario: Format check without modification

- **WHEN** a developer runs `nixpkgs-fmt --check file.nix`
- **THEN** the tool checks if formatting is correct
- **AND** no changes are written to the file
- **AND** exit code 1 indicates formatting needed
- **AND** exit code 0 indicates file is already formatted

#### Scenario: Alternative formatter (alejandra)

- **WHEN** a developer runs `alejandra file.nix`
- **THEN** the file is formatted with more opinionated style
- **AND** multi-line expressions are formatted differently than nixpkgs-fmt
- **AND** the result is valid Nix syntax

### Requirement: Nix Code Linting

The system SHALL detect anti-patterns and code smells in Nix expressions.

#### Scenario: Detect anti-patterns with statix

- **WHEN** a developer runs `statix check .`
- **THEN** all .nix files in the directory are analyzed
- **AND** anti-patterns are reported with file path and line number
- **AND** suggested fixes are provided when available
- **AND** exit code indicates number of issues found

#### Scenario: Auto-fix detected issues

- **WHEN** a developer runs `statix fix .`
- **THEN** auto-fixable issues are corrected in-place
- **AND** a summary of applied fixes is displayed
- **AND** manual intervention issues are still reported

#### Scenario: Detect dead code with deadnix

- **WHEN** a developer runs `deadnix .`
- **THEN** unused let bindings are identified
- **AND** unused function arguments are reported
- **AND** file paths and line numbers are shown

### Requirement: Binary Cache Management

The system SHALL utilize binary caches to accelerate builds.

#### Scenario: Configure cachix cache

- **WHEN** cachix is configured in nix.settings.substituters
- **THEN** Nix checks configured caches before building
- **AND** cached derivations are downloaded instead of built
- **AND** signature verification is performed using trusted-public-keys
- **AND** fallback to building occurs if no cache hit

#### Scenario: Use community caches

- **WHEN** the system is configured with nix-community.cachix.org
- **THEN** common development tools are available pre-built
- **AND** build times for tools like direnv, statix are minimal
- **AND** CUDA packages can use cuda-maintainers.cachix.org

### Requirement: Development Shell Enhancement

The system SHALL provide rich development shell experiences.

#### Scenario: Enhanced shell with direnv integration

- **WHEN** direnv loads a flake-based development shell
- **THEN** the shell prompt indicates the active environment
- **AND** shell hooks execute automatically
- **AND** environment variables are set correctly
- **AND** tools from the devShell are in PATH

#### Scenario: Multiple development shells

- **WHEN** a flake defines multiple devShells (default, agentshell)
- **THEN** direnv can be configured to use a specific shell
- **AND** the .envrc file can specify `use flake .#agentshell`
- **AND** different directories can use different shells

### Requirement: Package Derivation Generation

The system SHALL support generating Nix derivations from existing projects.

#### Scenario: Generate derivation for new package

- **WHEN** a developer runs `nix-init` in a project directory
- **THEN** the tool detects the project type (e.g., Rust, Python, Node.js)
- **AND** prompts for package metadata (name, version, description)
- **AND** generates a default.nix or flake.nix
- **AND** the generated file can be used to build the project

#### Scenario: Language-specific package manager integration

- **WHEN** a project uses npm/pip/cargo with lock files
- **THEN** dream2nix can generate Nix expressions
- **AND** dependency graphs are converted to Nix derivations
- **AND** the result integrates with existing Nix workflows

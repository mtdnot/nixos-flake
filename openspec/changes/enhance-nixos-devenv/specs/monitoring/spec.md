# System Monitoring and Visibility Capability

## ADDED Requirements

### Requirement: Enhanced System Resource Monitoring

The system SHALL provide modern, interactive system resource monitoring.

#### Scenario: Real-time system monitoring with btop

- **WHEN** a developer runs `btop`
- **THEN** an interactive TUI displays CPU usage per core
- **AND** memory usage is shown with breakdown (used/cached/available)
- **AND** disk I/O statistics are displayed in real-time
- **AND** network traffic is monitored per interface
- **AND** process list is sortable by CPU, memory, disk, network

#### Scenario: GPU monitoring for CUDA development

- **WHEN** a developer runs `btop` on a system with NVIDIA GPU
- **THEN** GPU utilization is displayed if supported
- **AND** GPU memory usage is shown
- **AND** CUDA processes are listed

#### Scenario: Alternative monitoring with bottom

- **WHEN** a developer runs `btm` (bottom)
- **THEN** a Rust-based monitoring interface is displayed
- **AND** customizable widgets show system metrics
- **AND** cross-platform behavior is consistent
- **AND** battery information is shown on laptops

### Requirement: Nix Dependency Exploration

The system SHALL provide tools to explore and understand Nix dependency graphs.

#### Scenario: Interactive dependency tree browsing

- **WHEN** a developer runs `nix-tree /nix/store/...-package`
- **THEN** an interactive TUI displays the dependency tree
- **AND** dependencies can be expanded/collapsed
- **AND** package sizes are shown for each derivation
- **AND** total closure size is calculated
- **AND** why-depends paths can be explored

#### Scenario: Find why a package depends on another

- **WHEN** a developer navigates the nix-tree interface
- **THEN** they can search for a specific package in the tree
- **AND** highlight the dependency path from root to target
- **AND** see all reverse dependencies (what depends on this)

### Requirement: Configuration Change Visualization

The system SHALL provide tools to understand differences between Nix configurations.

#### Scenario: Compare two derivations

- **WHEN** a developer runs `nix-diff derivation1.drv derivation2.drv`
- **THEN** differences in inputs are highlighted
- **AND** changed environment variables are shown
- **AND** different build dependencies are listed
- **AND** the output explains why rebuilds would occur

#### Scenario: Compare NixOS generations

- **WHEN** a developer runs `nix-diff` on two system profiles
- **THEN** packages added/removed/updated are listed
- **AND** configuration changes are highlighted
- **AND** the impact on system closure size is calculated

### Requirement: NixOS Option Documentation Access

The system SHALL provide searchable access to NixOS configuration options.

#### Scenario: Search configuration options

- **WHEN** a developer runs `nixos-option services.nginx`
- **THEN** all nginx-related options are listed
- **AND** current values are shown
- **AND** option types and defaults are displayed
- **AND** documentation strings are included

#### Scenario: Find option definition location

- **WHEN** a developer queries a specific option
- **THEN** the file and line number where it's defined is shown
- **AND** the module hierarchy is displayed
- **AND** declared by modules are listed

### Requirement: Build and Evaluation Diagnostics

The system SHALL provide detailed diagnostics for build and evaluation issues.

#### Scenario: Verbose build output analysis

- **WHEN** a build fails and developer reviews logs
- **THEN** nix-output-monitor highlights error messages
- **AND** build phases are clearly separated
- **AND** timing information for each phase is available
- **AND** environment variables can be inspected

#### Scenario: Store path size analysis

- **WHEN** a developer wants to understand disk usage
- **THEN** `nix path-info -rsSh` shows closure sizes
- **AND** dependencies are listed with individual sizes
- **AND** total closure size is calculated
- **AND** results can be sorted by size

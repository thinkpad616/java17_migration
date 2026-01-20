#!/usr/bin/env bash

# -------------------------------
# Install jenv via Homebrew
# -------------------------------
_brew_install_jenv() {
  echo "Installing jenv via Homebrew"
  brew install jenv
  echo "Finished installing jenv via Homebrew"
}

# -------------------------------
# Clone jenv manually if brew unavailable
# -------------------------------
_clone_jenv_optional() {
  if [ ! -d ~/.jenv ]; then
    # If dev can't clone from public GitHub we exit forcibly here
    git clone https://github.com/jenv/jenv.git ~/.jenv || { 
      echo "Failed to configure jenv" >&2
      exit 1
    }
  fi
}

# -------------------------------
# Configure jenv for bash shells
# -------------------------------
_configure_jenv_bash() {
  if [ -f ~/.bash_profile ]; then
    if ! grep -q "jenv" ~/.bash_profile; then
      echo 'export PATH="$HOME/.jenv/bin:$PATH"' >> ~/.bash_profile
      echo 'eval "$(jenv init -)"' >> ~/.bash_profile
    fi
  fi
}

# -------------------------------
# Configure jenv for zsh shells
# -------------------------------
_configure_jenv_zsh() {
  if [ -f ~/.zshrc ]; then
    if ! grep -q "jenv" ~/.zshrc; then
      echo 'export PATH="$HOME/.jenv/bin:$PATH"' >> ~/.zshrc
      echo 'eval "$(jenv init -)"' >> ~/.zshrc
    fi
  fi
}

# -------------------------------
# Install jenv (detect brew or clone)
# -------------------------------
install_jenv() {
  if ! command -v jenv >/dev/null; then
    if command -v brew >/dev/null; then
      _brew_install_jenv
    else
      _clone_jenv_optional
    fi

    _configure_jenv_bash
    _configure_jenv_zsh

    # ensure jenv can be used in current shell
    eval "$(jenv init -)"
  else
    if [ "quieter" != "$1" ]; then
      echo "jenv is already installed!"
    fi
  fi
}

# -------------------------------
# Self-service installation for Corretto 17 (macOS)
# -------------------------------
_self_service_install_java_17() {
  echo "Install Amazon Corretto 17 (Java) from Self Service."
  echo "Once installed, please close Self Service to continue..."
  sleep 3

  open --wait-apps "selfservice://content?action=search&term=Amazon Corretto JDK 17"

  if [ -d /Library/Java/JavaVirtualMachines/amazon-corretto-17.jdk ]; then
    echo "Finished installing Amazon Corretto 17 (Java)"
  else
    echo "Amazon Corretto 17 wasn't found at /Library/Java/JavaVirtualMachines/amazon-corretto-17.jdk"
  fi
}

# -------------------------------
# Install Java 17, using self-service if missing
# -------------------------------
install_java17() {
  if [ ! -d /Library/Java/JavaVirtualMachines/amazon-corretto-17.jdk ]; then
    _self_service_install_java_17
  else
    echo "Amazon Corretto 17 (Java) is already installed!"
  fi
}

# -------------------------------
# Configure jenv for Java 17
# -------------------------------
configure_jenv_java17() {
  if ! command -v jenv >/dev/null; then
    install_jenv "quieter"
  fi

  install_java17

  if [ -z "$(jenv versions --bare | grep -x "17.0.0")" ]; then
    echo "Configuring jenv for Java 17"
    jenv add /Library/Java/JavaVirtualMachines/amazon-corretto-17.jdk/Contents/Home
    echo "Finished configuring jenv for Java 17"
  fi
}

# -------------------------------
# Run OpenRewrite migration for Java 17 upgrade
# -------------------------------
run_migration() {
  configure_jenv_java17

  echo "Running OpenRewrite for migration"

  target_version="1.0.9"

  if [[ ! ${target_version} =~ ^[0-9]+\.[0-9]+ ]]; then
    target_version="1.0.9"
  fi

  rewrite_maven_plugin="5.2.6"
  bt_rewrite_module="com.capitalone.dsd.identity:rewrite-modules:${target_version}"

  all_modules="org.openrewrite.recipes:rewrite-migrate-java:2.0.5"
  all_modules="${all_modules},org.openrewrite.recipes:rewrite-spring:5.0.5"
  all_modules="${all_modules},org.openrewrite.recipes:rewrite-testing-frameworks:2.0.6"
  all_modules="${all_modules},${bt_rewrite_module}"

  # Java 17 recipes
  all_recipes="org.openrewrite.java.migrate.UpgradeToJava17"
  all_recipes="${all_recipes},org.openrewrite.java.spring.boot2.SpringBoot2Junit4to5Migration"
  all_recipes="${all_recipes},org.openrewrite.java.testing.junit5.UseMockitoExtension"
  all_recipes="${all_recipes},org.openrewrite.java.testing.mockito.MockitoJUnitRunnerSilentToExtension"
  all_recipes="${all_recipes},com.capitalone.dsd.identity.ConsumerIdentityJava17"

  set -x

  ### Note: all maven invocations below need to be done via CodeGenie system’s maven.
  mvn -ntp -U org.openrewrite.maven:rewrite-maven-plugin:${rewrite_maven_plugin}:run \
    -DactiveRecipes="${all_recipes}" \
    -Drewrite.failOnDryRunResults=true

  set +x

  echo "Finished running OpenRewrite for migration"
  echo "17.0" > .java-version
  exit
}

# -------------------------------
# Main Menu
# -------------------------------
echo "What do you want to do?"
select s in "Configure Java 17 and Migrate" "Configure Java 17" "Quit"; do
  case $s in
    "Configure Java 17 and Migrate") run_migration;;
    "Configure Java 17") configure_jenv_java17;;
    "Quit") exit;;
  esac
done

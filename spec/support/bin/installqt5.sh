#!/bin/sh

# Taken from: https://gist.github.com/jakecraige/50c122c8ae860f7595a4

# Exit if any subcommand fails
set -e

if [ ! -d "/opt/qt55" ]; then
  echo "Installing QT 5..."
  yes y | sudo add-apt-repository ppa:beineri/opt-qt551
  sudo apt-get update
  sudo apt-get update -o Dir::Etc::sourcelist="sources.list.d/beineri-opt-qt551-precise.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
  sudo apt-get install qt55webkit libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev qt55declarative qt55location qt55sensors
  echo "QT 5 installed."
fi

echo "source /opt/qt55/bin/qt55-env.sh" >> ~/.circlerc

-- Separate database used by the automated test suite (phpunit.xml).
-- The MySQL entrypoint runs this file as root on first initialization.
CREATE DATABASE IF NOT EXISTS delivery_platform_test
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Guarantee the application user can run the test suite regardless of the
-- order in which the entrypoint creates users and runs init scripts.
CREATE USER IF NOT EXISTS 'delivery'@'%' IDENTIFIED BY 'secret';
GRANT ALL PRIVILEGES ON delivery_platform_test.* TO 'delivery'@'%';
GRANT ALL PRIVILEGES ON delivery_platform.* TO 'delivery'@'%';
FLUSH PRIVILEGES;

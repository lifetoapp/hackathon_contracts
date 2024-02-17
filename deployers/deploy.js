const deployers = require('../deployers/life2app.deployer');

(async () => {
  try {
    await deployers.deploy();
  } catch (error) {
    console.error(error);
  }
  process.exit(0);
})();

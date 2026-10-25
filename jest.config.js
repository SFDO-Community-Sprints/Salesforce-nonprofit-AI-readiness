const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');

module.exports = {
    ...jestConfig,
    moduleNameMapper: {
        ...(jestConfig.moduleNameMapper || {}),
        // CSS-only shared style module (no JS entry point), resolved explicitly for Jest.
        '^c/airStyles$': '<rootDir>/force-app/main/default/lwc/airStyles/airStyles.css'
    },
    modulePathIgnorePatterns: ['<rootDir>/.localdevserver']
};

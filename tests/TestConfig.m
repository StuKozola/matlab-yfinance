% SPDX-FileCopyrightText: 2026 Stu Kozola
% SPDX-License-Identifier: Apache-2.0

classdef TestConfig < matlab.unittest.TestCase
    %TESTCONFIG Verify process-local configuration APIs.

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            projectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(projectRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, "tests")));
        end
    end

    methods (TestMethodSetup)
        function resetConfig(testCase)
            yfinance.internal.configStore(Reset=true);
            testCase.addTeardown(@() yfinance.internal.configStore(Reset=true));
        end
    end

    methods (Test)
        function configReturnsDefaults(testCase)
            currentConfig = yfinance.config();

            testCase.verifyEqual(currentConfig.network.retries, 2);
            testCase.verifyEqual(currentConfig.network.proxy, "");
            testCase.verifyFalse(currentConfig.debug.logging);
            testCase.verifyEqual(currentConfig.session.timeout, 30);
            testCase.verifyTrue(currentConfig.session.useCredentials);
        end

        function setConfigAffectsNewSessions(testCase)
            yfinance.setConfig( ...
                Timeout=12, ...
                Retries=4, ...
                UserAgent="test-agent", ...
                RetryDelay=0, ...
                UseCredentials=false);

            session = yfinance.internal.Session();

            testCase.verifyEqual(session.Timeout, 12);
            testCase.verifyEqual(session.MaxRetries, 4);
            testCase.verifyEqual(session.UserAgent, "test-agent");
            testCase.verifyEqual(session.RetryDelay, 0);
            testCase.verifyFalse(session.UseCredentials);
        end

        function upstreamCompatibleAliasesUpdateConfig(testCase)
            cacheLocation = string(tempdir);

            yfinance.set_config(proxy="http://localhost:8080", retries=1);
            yfinance.enable_debug_mode();
            yfinance.set_tz_cache_location(cacheLocation);

            currentConfig = yfinance.config();
            session = yfinance.internal.Session();

            testCase.verifyEqual(currentConfig.network.proxy, "http://localhost:8080");
            testCase.verifyEqual(currentConfig.network.retries, 1);
            testCase.verifyTrue(currentConfig.debug.logging);
            testCase.verifyEqual(currentConfig.timezoneCacheLocation, cacheLocation);
            testCase.verifyTrue(session.DebugMode);
        end

        function setConfigCanDisableDebugLogging(testCase)
            yfinance.enableDebugMode();

            currentConfig = yfinance.setConfig(DebugLogging=false, HideExceptions=false);

            testCase.verifyFalse(currentConfig.debug.logging);
            testCase.verifyFalse(currentConfig.debug.hide_exceptions);
        end
    end
end

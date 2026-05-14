function plan = buildfile
%BUILDFILE Build tasks for matlab-yfinance.

import matlab.buildtool.tasks.CodeIssuesTask
import matlab.buildtool.tasks.TestTask

plan = buildplan(localfunctions);

plan("test") = TestTask("tests");
plan("check") = CodeIssuesTask(["+yfinance", "tests"]);

plan.DefaultTasks = "test";
end


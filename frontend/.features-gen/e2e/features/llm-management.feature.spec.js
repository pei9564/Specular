// Generated from: e2e/features/llm-management.feature
import { test } from "playwright-bdd";

test.describe('LLM 管理介面', () => {

  test('使用者進入 LLM 列表頁面', async ({ Given, When, Then, page }) => { 
    await Given('使用者已開啟瀏覽器', null, { page }); 
    await When('使用者導航到 "/llms" 頁面', null, { page }); 
    await Then('頁面標題應包含 "LLM"', null, { page }); 
  });

  test('使用者新增 LLM 配置', async ({ Given, When, Then, And, page }) => { 
    await Given('使用者在 LLM 列表頁面', null, { page }); 
    await When('使用者點擊 "新增 LLM" 按鈕', null, { page }); 
    await And('使用者在 "模型 ID" 欄位輸入 "gpt-4o"', null, { page }); 
    await And('使用者在 "供應商" 欄位輸入 "OpenAI"', null, { page }); 
    await And('使用者點擊 "儲存" 按鈕', null, { page }); 
    await Then('應顯示成功訊息', null, { page }); 
    await And('列表應包含 "gpt-4o"', null, { page }); 
  });

});

// == technical section ==

test.use({
  $test: [({}, use) => use(test), { scope: 'test', box: true }],
  $uri: [({}, use) => use('e2e/features/llm-management.feature'), { scope: 'test', box: true }],
  $bddFileData: [({}, use) => use(bddFileData), { scope: "test", box: true }],
});

const bddFileData = [ // bdd-data-start
  {"pwTestLine":6,"pickleLine":4,"tags":[],"steps":[{"pwStepLine":7,"gherkinStepLine":5,"keywordType":"Context","textWithKeyword":"假設使用者已開啟瀏覽器","stepMatchArguments":[]},{"pwStepLine":8,"gherkinStepLine":6,"keywordType":"Action","textWithKeyword":"當使用者導航到 \"/llms\" 頁面","stepMatchArguments":[{"group":{"start":7,"value":"\"/llms\"","children":[{"start":8,"value":"/llms","children":[{"children":[]}]},{"children":[{"children":[]}]}]},"parameterTypeName":"string"}]},{"pwStepLine":9,"gherkinStepLine":7,"keywordType":"Outcome","textWithKeyword":"那麼頁面標題應包含 \"LLM\"","stepMatchArguments":[{"group":{"start":8,"value":"\"LLM\"","children":[{"start":9,"value":"LLM","children":[{"children":[]}]},{"children":[{"children":[]}]}]},"parameterTypeName":"string"}]}]},
  {"pwTestLine":12,"pickleLine":9,"tags":[],"steps":[{"pwStepLine":13,"gherkinStepLine":10,"keywordType":"Context","textWithKeyword":"假設使用者在 LLM 列表頁面","stepMatchArguments":[{"group":{"start":5,"value":"LLM","children":[]},"parameterTypeName":"word"}]},{"pwStepLine":14,"gherkinStepLine":11,"keywordType":"Action","textWithKeyword":"當使用者點擊 \"新增 LLM\" 按鈕","stepMatchArguments":[{"group":{"start":6,"value":"\"新增 LLM\"","children":[{"start":7,"value":"新增 LLM","children":[{"children":[]}]},{"children":[{"children":[]}]}]},"parameterTypeName":"string"}]},{"pwStepLine":15,"gherkinStepLine":12,"keywordType":"Action","textWithKeyword":"並且使用者在 \"模型 ID\" 欄位輸入 \"gpt-4o\"","stepMatchArguments":[{"group":{"start":5,"value":"\"模型 ID\"","children":[{"start":6,"value":"模型 ID","children":[{"children":[]}]},{"children":[{"children":[]}]}]},"parameterTypeName":"string"},{"group":{"start":18,"value":"\"gpt-4o\"","children":[{"start":19,"value":"gpt-4o","children":[{"children":[]}]},{"children":[{"children":[]}]}]},"parameterTypeName":"string"}]},{"pwStepLine":16,"gherkinStepLine":13,"keywordType":"Action","textWithKeyword":"並且使用者在 \"供應商\" 欄位輸入 \"OpenAI\"","stepMatchArguments":[{"group":{"start":5,"value":"\"供應商\"","children":[{"start":6,"value":"供應商","children":[{"children":[]}]},{"children":[{"children":[]}]}]},"parameterTypeName":"string"},{"group":{"start":16,"value":"\"OpenAI\"","children":[{"start":17,"value":"OpenAI","children":[{"children":[]}]},{"children":[{"children":[]}]}]},"parameterTypeName":"string"}]},{"pwStepLine":17,"gherkinStepLine":14,"keywordType":"Action","textWithKeyword":"並且使用者點擊 \"儲存\" 按鈕","stepMatchArguments":[{"group":{"start":6,"value":"\"儲存\"","children":[{"start":7,"value":"儲存","children":[{"children":[]}]},{"children":[{"children":[]}]}]},"parameterTypeName":"string"}]},{"pwStepLine":18,"gherkinStepLine":15,"keywordType":"Outcome","textWithKeyword":"那麼應顯示成功訊息","stepMatchArguments":[]},{"pwStepLine":19,"gherkinStepLine":16,"keywordType":"Outcome","textWithKeyword":"並且列表應包含 \"gpt-4o\"","stepMatchArguments":[{"group":{"start":6,"value":"\"gpt-4o\"","children":[{"start":7,"value":"gpt-4o","children":[{"children":[]}]},{"children":[{"children":[]}]}]},"parameterTypeName":"string"}]}]},
]; // bdd-data-end
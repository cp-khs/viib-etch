# viib-etch

LLM 통합을 통한 코딩 에이전트 구축을 위한 강력한 Node.js 라이브러리입니다. Cursor IDE와 같은 AI 기반 개발 도구를 위해 설계된 viib-etch는 채팅 세션 관리, 도구 실행, 스트리밍 응답 처리, 대규모 언어 모델과의 복잡한 다중 턴 대화 처리를 위한 완전한 인터페이스를 제공합니다.

## 주요 기능

- 🤖 **다중 모델 지원**: OpenAI, OpenRouter 및 기타 호환 API와 함께 작동
- 💬 **채팅 세션 관리**: 자동 저장/로드 기능이 있는 영구 채팅 세션
- 🔧 **도구 호출**: 자동 도구 실행을 지원하는 함수 호출 기능 내장
- 🧾 **도구 차이점**: 파일 수정 도구의 diff/패치를 `ChatSession.data`에 저장
- 📡 **스트리밍**: 응답 및 추론의 실시간 스트리밍
- 🎣 **훅 시스템**: 요청, 응답 및 도구 호출을 모니터링하기 위한 포괄적인 이벤트 훅
- 📝 **시스템 프롬프트**: 파일에서 동적 시스템 프롬프트 로드
- 🔄 **API 라우팅**: `/v1/chat/completions` 및 `/v1/responses` API 간 자동 라우팅
- 🛠️ **풍부한 도구 세트**: 파일 작업, 터미널 명령, 코드 검색 등을 위한 사전 구축된 도구
- 💾 **세션 지속성**: 재시작 시에도 채팅 세션 저장 및 복원

## 설치

```bash
npm install
```

## 빠른 시작

```javascript
const { createChat, openChat } = require('./viib-etch');

// 콘솔 로깅이 있는 새 채팅 세션 생성
const llm = createChat('gpt-5.1-coder', false, null, 'console');

// 메시지 전송
await llm.send('Python으로 hello world 함수를 작성해줘');

// 응답은 자동으로 채팅 기록에 추가됩니다

// 나중에 동일한 채팅 세션을 엽니다
const llm2 = openChat(llm.chat.id, null, 'console');
await llm2.send('이제 오류 처리를 추가해줘');
```

## 기본 UI (마운트 가능)

`viib-etch`에는 단일 파일로 된 최소한의 임베드 가능한 UI가 포함되어 있습니다: `viib-etch-ui.js`.

### 자체 Node 서버에 마운트

```javascript
const http = require('http');
const { createViibEtchUI } = require('./viib-etch-ui');

const ui = createViibEtchUI({
  token: process.env.VIIB_ETCH_UI_TOKEN, // 필수 (간단한 Bearer 토큰 인증)
  // chatsDir: '/path/to/chats',
  // modelsFile: '/path/to/viib-etch-models.json',
});

http.createServer((req, res) => {
  const handled = ui.handler(req, res);
  if (!handled) {
    res.statusCode = 404;
    res.end('not found');
  }
}).listen(8080, '0.0.0.0');
```

- `GET /ui`에서 UI를 엽니다 (`Authorization: Bearer <token>` 필요).
- UI 스크립트는 `GET /viib-etch-ui.js`에서 제공됩니다.

### 빠른 HTTPS 헬퍼 (기본값)

```javascript
const { createViibEtchUI } = require('./viib-etch-ui');
const ui = createViibEtchUI({ token: 'my-token' });
ui.createHttpsServer({ port: 8443, certPath: 'zdte_cert.crt', keyPath: 'zdte_key.key' }).listen();
```

```javascript
const { createChat } = require('./viib-etch');

// 간단한 로깅이 있는 새 채팅 세션 생성 (문자열 단축키)
const coder = createChat('gpt-5.1-coder', true, null, 'brief')

// 'web-search' 도구를 구현하도록 요청합니다 (이 글을 쓰는 시점에는 구현되지 않음).
// 이 요청은 Cursor IDE와 같은 일반 코딩 에이전트가 수행하는 작업을 완전히 수행합니다.
response = await coder.send("Brave 웹 검색을 사용하여 web-search 도구를 구현해줘. 테스트 케이스를 추가하고 실행한 후 문제가 있으면 수정해줘.", { stream: true})
```


## 설정

### 모델 설정

모델은 `viib-etch-models.json`에 구성됩니다:

```json
{
  "name": "gpt-5.1-coder",
  "model": "gpt-5.1",
  "baseUrl": "https://api.openai.com/v1",
  "api_key_file": "/path/to/.openai-api-key",
  "system_prompt_file": "/path/to/viib-etch.system.coder.prompt",
  "tools": ["run_terminal_cmd", "read_file", "apply_patch"],
  "reasoning_effort": "high"
}
```

### API 키

API 키는 다음을 통해 제공할 수 있습니다:
1. **파일 경로** (권장): 모델 구성에서 `api_key_file` 설정
2. **환경 변수**: OpenAI 모델의 경우 `OPENAI_API_KEY`
3. **직접 구성**: 모델 구성에서 `api_key` (권장하지 않음)

**`api_key_file`의 파일 경로 해석:**
- **절대 경로**: 그대로 사용
- **상대 경로**: 다음 순서로 해석:
  1. 현재 작업 디렉토리
  2. 모델 파일이 포함된 디렉토리 (`viib-etch-models.json`)
  3. 모듈 디렉토리 (`__dirname`)

### 시스템 프롬프트

시스템 프롬프트는 다음과 같을 수 있습니다:
- **파일 기반**: 모델 구성에서 `system_prompt_file` 설정 (각 요청마다 다시 로드됨)
- **인라인**: 모델 구성에서 `system_prompt` 설정

**`system_prompt_file`의 파일 경로 해석:**
- **절대 경로**: 그대로 사용
- **상대 경로**: 다음 순서로 해석:
  1. 현재 작업 디렉토리
  2. 모델 파일이 포함된 디렉토리 (`viib-etch-models.json`)
  3. 모듈 디렉토리 (`__dirname`)

## 핵심 API

### ChatModel

구성된 LLM 모델을 나타냅니다:

```javascript
const { ChatModel } = require('./viib-etch');

const models = ChatModel.loadModels('viib-etch-models.json');
const model = models.find(m => m.name === 'gpt-5.1-coder');
```

### ChatSession

대화 상태를 관리합니다:

```javascript
const { ChatSession } = require('./viib-etch');

// 새 세션 생성
const session = new ChatSession({
  title: '내 채팅',
  model_name: 'gpt-5.1-coder'
});

// 지속성 활성화
session.enablePersistence('./chats');

// 메시지 추가
session.addMessage({ role: 'user', content: '안녕하세요' });
session.addMessage({ role: 'assistant', content: '안녕하세요!' });

// 저장 및 로드
session.save();
const loaded = ChatSession.load(session.id);
```

#### `ChatSession.data`의 도구 차이점

파일 수정 도구는 나중에 검사할 수 있도록 세션 데이터에 diff 및 패치 명령을 저장할 수 있습니다:

- `session.data.diffs[toolCallId] = { diff, patchCommand, toolName }`

참고:
- 이러한 필드는 세션이 영구적인 경우 유지됩니다.
- `_diff` / `_patchCommand`는 도구 메시지 콘텐츠에서 제거됩니다 (대신 `session.data`에 있음).

### ChatLLM

LLM 상호 작용을 위한 주요 인터페이스:

```javascript
const { ChatLLM } = require('./viib-etch');

// 훅으로 생성
const llm = ChatLLM.newChatSession('gpt-5.1-coder', false, null, {
  onRequestStart: () => console.log('요청 시작'),
  onRequestDone: (elapsed) => console.log(`요청이 ${elapsed}ms 걸렸습니다`),
  onReasoningStart: () => console.log('추론 중...'),
  onReasoningData: (chunk) => process.stdout.write(chunk),
  onReasoningDone: (fullReasoning, elapsed) => console.log(`\n추론 완료 (${elapsed}ms)`),
  onResponseStart: () => console.log('응답 시작'),
  onResponseData: (chunk) => process.stdout.write(chunk),
  onResponseDone: (content, elapsed) => console.log(`\n응답 완료 (${elapsed}ms)`),
  onToolCallStart: (toolCall, args) => console.log(`도구: ${toolCall.function.name}`),
  onToolCallData: (toolCall, data) => console.log('도구 데이터:', data),
  onToolCallEnd: (toolCall, result, elapsed) => console.log(`도구 완료 (${elapsed}ms)`),
  onTitle: (title) => console.log(`채팅 제목: ${title}`)
});

// 메시지 전송
await llm.send('피보나치 수를 계산하는 함수를 작성해줘');

// 또는 더 많은 제어를 위해 complete() 사용
const result = await llm.complete({
  stream: true,
  temperature: 0.7,
  max_tokens: 1000,
  tools: customTools
});
```

## 사용 가능한 도구

viib-etch에는 코딩 에이전트를 위한 포괄적인 도구 세트가 포함되어 있습니다:

### 파일 작업
- **`read_file`**: 줄 번호, offset/limit 지원 및 이미지에 대한 base64 인코딩으로 파일 읽기
- **`apply_patch`**: 파일에 구조화된 패치 적용 (추가, 업데이트, 삭제)
- **`delete_file`**: 우아한 오류 처리로 파일 삭제
- **`list_dir`**: glob 필터링으로 디렉토리 내용 나열
- **`glob_file_search`**: 패턴과 일치하는 파일 검색, 수정 시간순 정렬

`apply_patch` 및 `delete_file`의 경우, 라이브러리는 통합 diff (그리고 `apply_patch`의 경우 패치 텍스트)를 도구 호출 ID로 키가 지정된 `ChatSession.data.diffs`에 기록합니다.

### 코드 작업
- **`rg`**: ripgrep을 사용한 빠른 텍스트 검색 (.gitignore 존중)
- **`read_lints`**: IDE에서 린터 오류 읽기

### 터미널
- **`run_terminal_cmd`**: 스트리밍 출력, 백그라운드 지원 및 훅으로 터미널 명령 실행

### 프로젝트 관리
- **`todo_write`**: 세션 데이터에서 할 일 목록 관리 (생성, 업데이트, 병합, 삭제)
- **`update_memory`**: 세션 데이터에 지식 저장 및 검색

### 웹
- **`web_search`**: 웹 검색 기능 (구성된 경우)

## 도구 실행

LLM이 요청하면 도구가 자동으로 실행됩니다:

```javascript
const llm = ChatLLM.newChatSession('gpt-5.1-coder', false, null, {
  onToolCallStart: (toolCall, args) => {
    console.log(`실행 중: ${toolCall.function.name}`, args);
  },
  onToolCallEnd: (toolCall, result) => {
    console.log(`결과:`, result);
  }
});

// 이제 LLM이 자동으로 도구를 사용할 수 있습니다
await llm.send('src/index.js 파일을 읽고 개선 사항을 제안해줘');
```

## 스트리밍

스트리밍 및 비스트리밍 모드가 모두 지원됩니다:

```javascript
// 비스트리밍
const result = await llm.complete({ stream: false });
console.log(result.content);

// 스트리밍
const result = await llm.complete({ stream: true });
// 콘텐츠는 onResponseData 훅을 통해 스트리밍됩니다
// result.content에는 전체 응답이 포함됩니다
```

## API 라우팅

viib-etch는 요청을 적절한 API로 자동 라우팅합니다:

- **`/v1/chat/completions`**: GPT-4 및 이전 모델용
- **`/v1/responses`**: GPT-4o, GPT-5 및 최신 모델용 (response_id 지원)

라이브러리가 처리하는 것:
- 모델 기반 자동 API 선택
- 대화 연속성을 위한 응답 ID 관리
- 잘못된 응답 ID에 대한 오류 처리 및 재시도 논리
- API 간 도구 형식 정규화

## 편의 함수

```javascript
const {
  ChatModel,
  ChatSession,
  ChatLLM,
  setModelsFileName,
  getModelsFileName,
  setChatsDir,
  getChatsDir,
  consoleLogHooks,
  loadModels,
  loadChat,
  listChatSessions,
  createChat,
  openChat
} = require('./viib-etch');

// 모델 로드
const models = loadModels('viib-etch-models.json');

// 채팅 세션 로드 (ChatSession 반환)
const chat = loadChat('chat-id-here');

// 모든 채팅 세션 나열
const sessions = listChatSessions();
sessions.forEach(s => {
  console.log(`${s.id}: ${s.title} (${s.message_count} 메시지)`);
});

// 모델 파일 위치 구성
setModelsFileName('/path/to/custom-models.json');
const currentModelsFile = getModelsFileName();

// 채팅 디렉토리 위치 구성
setChatsDir('/path/to/custom-chats');
const currentChatsDir = getChatsDir();

// 문자열 훅으로 채팅 생성 (편리한 단축키)
const llm1 = createChat('gpt-5.1-coder', false, null, 'console');  // 전체 콘솔 로깅
const llm2 = createChat('gpt-5.1-coder', false, null, 'brief');     // 간단한 콘솔 로깅

// 사용자 정의 훅 객체로 채팅 생성
const llm3 = createChat('gpt-5.1-coder', false, null, 
  consoleLogHooks({ response: true, reasoning: true, tools: true })
);

// 기존 채팅 세션 열기 (ChatLLM 반환)
const llm4 = openChat('chat-id-here', null, 'console');  // 콘솔 훅으로
const llm5 = openChat('chat-id-here', null, 'brief');    // 간단한 훅으로
const llm6 = openChat('chat-id-here', null, customHooks); // 사용자 정의 훅으로
```

## 예제

### 기본 채팅

```javascript
const { createChat } = require('./viib-etch');

// 간단한 채팅
const llm = createChat('gpt-4.1-mini', false);
await llm.send('안녕하세요!');

// 콘솔 로깅과 함께
const llm2 = createChat('gpt-4.1-mini', false, null, 'console');
await llm2.send('안녕하세요!');
```

### 도구가 있는 채팅

```javascript
const { ChatLLM } = require('./viib-etch');
const { getToolDefinitions } = require('./viib-etch-tools');

// 도구 로드
const tools = getToolDefinitions('./viib-etch-tools.json', [
  'read_file',
  'apply_patch',
  'run_terminal_cmd'
]);

const llm = ChatLLM.newChatSession('gpt-5.1-coder', false, tools);
await llm.send('package.json을 읽고 버전을 2.0.0으로 업데이트해줘');
```

### 타사 도구 등록 (정의 + 핸들러)

런타임에 **도구 정의 + 핸들러**를 등록하여 외부에서 도구 시스템을 확장할 수 있습니다.
등록된 도구 정의는 `getToolDefinitions(...)`에 포함되고, 등록된 핸들러는 `executeTool(...)`에서 사용됩니다.

```javascript
const { registerTool } = require('./viib-etch-tools');

// 도구 정의 + 핸들러 등록 (viib-etch-tools.json에 존재할 필요 없음)
registerTool({
  type: 'function',
  function: {
    name: 'calculator',
    description: '기본 산술 표현식을 평가하고 숫자 결과를 반환합니다.',
    parameters: {
      type: 'object',
      additionalProperties: false,
      properties: { expression: { type: 'string' } },
      required: ['expression'],
    },
  },
}, async (args) => {
  const expr = String(args?.expression || '');
  // 예제 전용: 사용 사례에 적합하게 입력을 검증하세요.
  // eslint-disable-next-line no-new-func
  const result = Function(`"use strict"; return (${expr});`)();
  return { success: true, result };
});
```

그런 다음 도구를 빌드할 때 포함할 수 있습니다:

```javascript
const path = require('path');
const { getToolDefinitions } = require('./viib-etch-tools');

const toolsPath = path.join(__dirname, 'viib-etch-tools.json');
const tools = getToolDefinitions(toolsPath, ['calculator']);
```

### 영구 채팅 세션

```javascript
const { createChat, openChat } = require('./viib-etch');

// 영구 세션 생성
const llm = createChat('gpt-5.1-coder', true, null, 'console');
// 세션이 자동으로 ./chats/에 저장됩니다

// 나중에 세션 열기 (수동 로드보다 쉬움)
const llm2 = openChat(llm.chat.id, null, 'console');
await llm2.send('중단한 부분부터 계속해줘');
```

또는 하위 수준 API를 사용하여:

```javascript
const { ChatLLM, loadChat } = require('./viib-etch');

// 영구 세션 생성
const llm = ChatLLM.newChatSession('gpt-5.1-coder', true, null);
// 세션이 자동으로 ./chats/에 저장됩니다

// 나중에 세션을 수동으로 로드
const loaded = loadChat(llm.chat.id);
const llm2 = new ChatLLM(null, loaded);
```

### 사용자 정의 훅

```javascript
const hooks = {
  onRequestStart: async () => {
    console.log('🚀 요청 시작...');
  },
  onTitle: async (title) => {
    console.log(`📝 채팅 제목: ${title}`);
  },
  onResponseData: async (chunk) => {
    process.stdout.write(chunk);
  },
  onToolCallStart: async (toolCall, args) => {
    console.log(`🔧 ${toolCall.function.name}(${JSON.stringify(args)})`);
  },
  onToolCallEnd: async (toolCall, result, elapsed) => {
    console.log(`✅ ${elapsed}ms에 완료`);
  }
};

const llm = ChatLLM.newChatSession('gpt-5.1-coder', false, null, hooks);
```

## 테스트

테스트 스위트 실행:

```bash
# 도구 테스트
node test-viib-etch-tools.js

# 메인 라이브러리 테스트
node test-viib-etch.js
```

## 아키텍처

viib-etch는 다음과 같은 주요 구성 요소를 가진 코딩 에이전트를 위해 설계되었습니다:

1. **ChatModel**: 모델 구성 및 API 키 관리
2. **ChatSession**: 대화 상태 및 지속성
3. **ChatLLM**: LLM 상호 작용을 위한 주요 인터페이스
4. **도구 시스템**: 확장 가능한 도구 실행 프레임워크
5. **훅 시스템**: 이벤트 기반 모니터링 및 로깅

## 라이선스

자세한 내용은 LICENSE 파일을 참조하세요.

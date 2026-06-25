## Building a Production-Grade AI Chat App in Panel

Panel’s `pn.chat.ChatInterface` gives you a fast way to build an AI chat app without having to wire up every UI detail yourself. It handles the chat layout, message flow, and built-in controls, while you stay in charge of the callback logic and LLM execution flow. The ChatInterface is a high-level layout for user-friendly chat input and supports features like sending, rerunning, undoing, clearing, and stopping responses. [panel.holoviz](https://panel.holoviz.org/reference/chat/ChatInterface.html)

## 1. Start with the LLM client

The first thing to understand is that your app needs an LLM client, such as OpenAI, Anthropic, or a local model server. In a Panel app, it is best to create that client once outside the callback so it can be reused across the session instead of being recreated on every message. Streaming chat completions can then be handled with `stream=True`, which returns chunks of the response incrementally. [platform.openai](https://platform.openai.com/docs/guides/streaming-responses?api-mode=chat)

```python
import panel as pn
import openai

pn.extension()

# Create the client once
client = openai.AsyncOpenAI(api_key="YOUR_API_KEY")

async def callback(contents, user, instance):
    response = await client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": contents}]
    )
    return response.choices[0].message.content

chat_interface = pn.chat.ChatInterface(callback=callback)
chat_interface.servable()
```

## 2. Keep the conversation history

LLMs do not remember previous messages by themselves, so you need to send the conversation history with each new request. Panel’s `ChatInterface` stores chat messages in `instance.objects`, which makes it easy to rebuild the full prompt for the model. `panel.state` also provides session-level information for a running app, while Panel’s execution model keeps application state available across the session. [panel.holoviz](https://panel.holoviz.org/how_to/state/index.html)

A simple pattern is to start with a system message, then convert each chat item into the role format your model expects:

```python
async def callback(contents, user, instance):
    messages = [{"role": "system", "content": "You are a helpful assistant."}]

    for message in instance.objects:
        role = "assistant" if message.user == "AI" else "user"
        messages.append({"role": role, "content": message.object})

    stream = await client.chat.completions.create(
        model="gpt-4o",
        messages=messages,
        stream=True
    )
```

This turns the chat into a real conversation instead of a series of disconnected replies.

## 3. Let users stop generation

Long responses can take time, so a production app should let users interrupt the model when they no longer need the answer. Panel’s `ChatInterface` includes a stop button for async callbacks, and you can combine that with an event flag such as `asyncio.Event()` to break out of your streaming loop. OpenAI’s streaming API returns chunks that expose `delta.content`, which is designed for incremental output handling. [panel.holoviz](https://panel.holoviz.org/reference/chat/ChatInterface.html)

```python
import asyncio

async def callback(contents, user, instance):
    abort_event = asyncio.Event()
    instance.stop_event = abort_event

    stream = await client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": contents}],
        stream=True
    )

    message = ""
    async for chunk in stream:
        if abort_event.is_set():
            yield message + "\n\n*(Generation aborted)*"
            break

        content = chunk.choices[0].delta.content
        if content:
            message += content
            yield message
```

This pattern keeps the app responsive and gives the user control over long-running generations.

## 4. Think in sessions, not single prompts

For production apps, the main idea is to treat each browser session as its own chat context. If you need values to survive refreshes, use session-aware state such as `pn.session_state` or application-level variables, depending on your design. Panel’s docs also note that `ChatInterface` supports adaptive interruption behavior, which can help when a user sends a new message before the previous response finishes. [panel.holoviz](https://panel.holoviz.org/api/panel.chat.interface.html)

That means your app can feel conversational without losing control of the underlying logic.

## Architecture takeaways

- Keep the LLM client outside the callback so it can be reused across the session. [platform.openai](https://platform.openai.com/docs/guides/streaming-responses?api-mode=chat)
- Rebuild the prompt from chat history so the model sees the full conversation. [panel.holoviz](https://panel.holoviz.org/reference/chat/ChatInterface.html)
- Use streaming plus an abort signal to keep the app responsive. [platform.openai](https://platform.openai.com/docs/guides/streaming-responses?api-mode=chat)
- Store only the state you really need across refreshes. [panel.holoviz](https://panel.holoviz.org/how_to/streamlit_migration/session_state.html)

## Closing idea

A solid Panel AI app is not just about getting a response from the model. It is about managing state, preserving history, streaming output smoothly, and giving users control over the experience. Panel’s `ChatInterface` gives you a strong foundation for that, while still leaving room to grow into features like vector search and RAG later. [panel.holoviz](https://panel.holoviz.org/reference/chat/ChatInterface.html)

Would you like me to turn this into a polished Medium-style article with an engaging title, introduction, and conclusion?

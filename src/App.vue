<script setup>
import { ref, computed } from 'vue';
import { notification } from 'ant-design-vue';
//import { UploadChangeParam } from 'ant-design-vue';
import axios from "axios";

const baseURL = 'http://localhost:8000';

const api = axios.create({
  baseURL
})

const status = ref('');
const buttonStatus = ref(false);
const textarea = ref('');

const buttonName = computed(() => {
  return buttonStatus.value ? 'Stop' : 'Transcribe';
});

let ws;
let stream;
let recorder;

const handleSubmit = async () => {
  if (buttonStatus.value) {
    //    ws.close();
    recorder.stop();
    stream.getTracks().forEach(track => track.stop());
    ws.send(JSON.stringify({ event: 'end' }));
    buttonStatus.value = false;
    return;
  }
  buttonStatus.value = true;

  ws = new WebSocket("ws://localhost:8000/audio");

  ws.onmessage = (ev) => {
    const data = JSON.parse(ev.data);
    switch (data.event) {
      case "text":
        textarea.value += data.text;
        break;
      case "end":
        textarea.value += "\n";
        ws.close();
        break;
    }
  };

  ws.onerror = (ev) => {
    status.value = ev;
  };

  ws.onclose = () => {
    status.value = 'WebSocket closed';
  };

  ws.onopen = async () => {
    status.value = "Connected to FastAPI WebSocket";
    stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    recorder = new MediaRecorder(stream, { mimeType: "audio/webm" });

    recorder.ondataavailable = async e => {
      if (e.data.size > 0 && ws.readyState === WebSocket.OPEN) {
        const arrayBuffer = await e.data.arrayBuffer();
        const b64 = btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)));
        ws.send(JSON.stringify({ chunk: b64 }));
      }
    };

    recorder.start(200); // send every 200ms chunk
    console.log("Streaming audio...");
  };
};
</script>

<template>
  <div class="container">
    <div>
      Press the button to start recording and press it again for speech-to-text transcription.
    </div>
    <div>
      <a-button type="primary" @click="handleSubmit">{{ buttonName }}</a-button>
      Status: {{ status }}
    </div>
    <div>
      AI transcription:
      <a-textarea class="textarea" v-model:value="textarea" show-count />
    </div>
  </div>
</template>

<style scoped>
.container {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.input {}

.textarea {
  height: 200px;
}
</style>

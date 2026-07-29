import { mount } from "svelte";
import App from "./App.svelte";
import "@kenn-io/kit-ui/theme.css";
import "./app.css";

const target = document.getElementById("app");

if (!target) {
  throw new Error("Root element 'app' not found. Cannot mount application.");
}

mount(App, { target });

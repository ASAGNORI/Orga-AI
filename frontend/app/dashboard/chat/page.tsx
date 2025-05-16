'use client'

import Chat from "../../components/Chat";
import { useState } from "react";

export default function ChatPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold mb-6">Chat Assistant</h1>
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-4">
        <Chat />
      </div>
    </div>
  );
}
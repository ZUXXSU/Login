// Import necessary modules
const express = require('express');
const http = require('http');
const WebSocket = require('ws');

const PORT = process.env.PORT || 8080;

const app = express();
const server = http.createServer(app);

const wss = new WebSocket.Server({ server, path: '/chat' });

let isBroadcasting = false;
let broadcastInterval;
const clients = new Set(); 

const mockChats = [
    { user: 'Alice', message: 'Hey, how is everyone doing?' },
    { user: 'Bob', message: 'Doing great! Just finished a big project.' },
    { user: 'Charlie', message: 'I am new here, nice to meet you all!' },
    { user: 'Alice', message: 'Welcome Charlie!' },
    { user: 'David', message: 'Anyone seen the latest news?' },
];

let messageIndex = 0;

// Function to broadcast messages to all connected clients
function broadcastMessage() {
    // Get the next message from our mock data
    const chatData = mockChats[messageIndex % mockChats.length];
    messageIndex++;

    const payload = JSON.stringify({
        ...chatData,
        timestamp: new Date().toISOString(),
    });

    // Send the payload to every connected client
    clients.forEach(client => {
        // Check if the connection is still open before sending
        if (client.readyState === WebSocket.OPEN) {
            client.send(payload);
        }
    });
    console.log(`Broadcasted message: ${payload}`);
}

function startBroadcasting() {
    if (!broadcastInterval) {
        console.log('Starting WebSocket broadcast...');
        broadcastInterval = setInterval(broadcastMessage, 5000);
        isBroadcasting = true;
    }
}

function stopBroadcasting() {
    if (broadcastInterval) {
        console.log('Stopping WebSocket broadcast...');
        clearInterval(broadcastInterval);
        broadcastInterval = null;
        isBroadcasting = false;
    }
}


// --- 4. WebSocket Connection Handling ---
wss.on('connection', (ws) => {
    console.log('A new client connected to /chat');
    clients.add(ws); 

    ws.on('message', (message) => {
        console.log(`Received message => ${message}`);
    });

    ws.on('close', () => {
        console.log('Client has disconnected');
        clients.delete(ws); 
    });

    ws.on('error', (error) => {
        console.error('WebSocket error:', error);
    });
});


app.get('/toggle', (req, res) => {
    if (isBroadcasting) {
        stopBroadcasting();
        res.status(200).send({ status: 'stopped', message: 'WebSocket broadcasting has been stopped.' });
    } else {
        startBroadcasting();
        res.status(200).send({ status: 'started', message: 'WebSocket broadcasting has been started.' });
    }
});

app.get('/', (req, res) => {
    res.send('Server is running. Use /toggle to control the WebSocket.');
});

server.listen(PORT, () => {
    console.log(`Server is listening on http://localhost:${PORT}`);
    console.log(`WebSocket is available at ws://localhost:${PORT}/chat`);
});

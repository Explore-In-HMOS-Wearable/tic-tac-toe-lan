import { socket } from '@kit.NetworkKit';
import { buffer } from '@kit.ArkTS';

interface HttpRequest {
  method: string
  url: string
  protocol: string
  headers: Record<string, string>
  body: string
}

interface HttpResponse {
  result: string
  status: string
}

let tcpServer: socket.TCPSocketServer | null = null;

export async function initTCPServer(port: number, requestHandler: (request: HttpRequest) => Promise<HttpResponse>): Promise<void> {
  tcpServer = socket.constructTCPSocketServerInstance()
  await tcpServer.listen({ address: '0.0.0.0', port: port })
  tcpServer.on('connect', (cnn) => handleConnect(cnn, requestHandler))
}

async function handleConnect(connection: socket.TCPSocketConnection,
  requestHandler: (request: HttpRequest) => Promise<HttpResponse>): Promise<void> {
  connection.on('message', async (value: socket.SocketMessageInfo) => {
    let requestData = buffer.from(value.message).toString('utf-8')
    let httpRequest = parseHttpRequest(requestData)
    const response = await requestHandler(httpRequest)

    const headers = [
      `HTTP/1.1 ${response.status}`,
      `Content-Type: text/plain`,
      `Content-Length: ${response.result.length}`
    ].join('\n');

    const responseStr = [
      headers,
      response.result
    ].join('\n\n')

    await connection.send({ data: responseStr, encoding: 'utf-8' })
    connection.close()
  })
}

function parseHttpRequest(requestData: string): HttpRequest {
  const [head, ...rest] = requestData.split('\r\n\r\n');
  const lines = head.split('\r\n');
  const [method, url, protocol] = lines[0].split(' ');

  const headers = lines
    .slice(1)
    .reduce((acc, line) => {
      const [key, value] = line.split(': ');
      if (key && value !== undefined) {
        acc[key] = value;
      }
      return acc;
    }, {});

  const body = rest.join('\r\n\r\n');

  return {
    method,
    url,
    protocol,
    headers,
    body
  };
}
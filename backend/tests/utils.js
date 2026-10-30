import { createApp } from '../server.js';

let app = null;
let server = null;

export async function getTestApp() {
  if (!app) {
    app = await createApp();
  }
  return app;
}

export async function startTestServer(port = 0) {
  const testApp = await getTestApp();
  return new Promise((resolve) => {
    server = testApp.listen(port, '0.0.0.0', () => {
      const address = server.address();
      resolve({ app: testApp, server, port: address.port });
    });
  });
}

export async function stopTestServer() {
  if (server) {
    await new Promise((resolve) => server.close(resolve));
    server = null;
  }
}

export async function request(app, method, path, data = null, headers = {}) {
  const defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...headers
  };
  
  const options = {
    method: method.toUpperCase(),
    headers: defaultHeaders
  };
  
  if (data && ['POST', 'PUT', 'PATCH'].includes(method.toUpperCase())) {
    options.body = JSON.stringify(data);
  }
  
  const url = `http://localhost:${app.server.address().port}${path}`;
  const response = await fetch(url, options);
  
  let body = null;
  const contentType = response.headers.get('content-type');
  if (contentType && contentType.includes('application/json')) {
    body = await response.json();
  } else {
    body = await response.text();
  }
  
  return {
    status: response.status,
    statusText: response.statusText,
    headers: response.headers,
    body
  };
}

export async function get(app, path, headers) {
  return request(app, 'GET', path, null, headers);
}

export async function post(app, path, data, headers) {
  return request(app, 'POST', path, data, headers);
}

export async function put(app, path, data, headers) {
  return request(app, 'PUT', path, data, headers);
}

export async function patch(app, path, data, headers) {
  return request(app, 'PATCH', path, data, headers);
}

export async function del(app, path, headers) {
  return request(app, 'DELETE', path, null, headers);
}

export function expectSuccess(response, expectedStatus = 200) {
  expect(response.status).toBe(expectedStatus);
  expect(response.body).toBeDefined();
  return response.body;
}

export function expectError(response, expectedStatus, expectedMessage = null) {
  expect(response.status).toBe(expectedStatus);
  expect(response.body).toBeDefined();
  if (expectedMessage) {
    expect(response.body.error).toContain(expectedMessage);
  }
  return response.body;
}

export function expectPaginatedResponse(body) {
  expect(body).toHaveProperty('data');
  expect(body).toHaveProperty('pagination');
  expect(Array.isArray(body.data)).toBe(true);
  expect(body.pagination).toHaveProperty('total');
  expect(body.pagination).toHaveProperty('limit');
  expect(body.pagination).toHaveProperty('skip');
  expect(body.pagination).toHaveProperty('hasMore');
  return body;
}

export function expectHealthResponse(body) {
  expect(body).toHaveProperty('status', 'ok');
  expect(body).toHaveProperty('database');
  expect(body).toHaveProperty('collectionsCount');
  expect(body).toHaveProperty('version');
  expect(body).toHaveProperty('timestamp');
  return body;
}

export function expectDashboardStats(body) {
  expect(body).toHaveProperty('kpis');
  expect(body).toHaveProperty('machines');
  expect(body).toHaveProperty('attendance');
  expect(body).toHaveProperty('pendingTasksCount');
  expect(body).toHaveProperty('recentActivities');
  expect(body).toHaveProperty('monthlyData');
  return body;
}
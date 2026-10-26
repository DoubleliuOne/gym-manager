import http from '@ohos.net.http';
import router from '@ohos.router';
import { BusinessError } from '@kit.BasicServicesKit';

const BASE_URL: string = 'http://10.0.2.2:8080/api/v1';

export interface ApiResponse<T = object> {
  code: number;
  msg: string;
  data: T;
}

/* ========== 请求体类型 ========== */

export class LoginRequest {
  phone: string = '';
  password: string = '';
}

export class RegisterRequest {
  phone: string = '';
  password: string = '';
  name: string = '';
  role: string = 'member';
  specialty: string = '';
}

export class BookingRequest {
  memberId: number = 0;
  scheduleId: number = 0;
}

export class CancelBookingRequest {
  memberId: number = 0;
}

export class CheckinRequest {
  bookingId: number = 0;
  method: number = 0;
}

export class PurchaseCardRequest {
  memberId: number = 0;
  templateId: number = 0;
}

/* ========== HTTP 请求封装 ========== */

function request<T>(
  method: http.RequestMethod,
  path: string,
  body?: object
): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    const httpRequest = http.createHttp();
    const url = BASE_URL + path;
    const token: string = AppStorage.get<string>('token') ?? '';

    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    if (token) {
      headers['Authorization'] = 'Bearer ' + token;
    }

    let extraData: string | undefined;
    if (body !== undefined) {
      extraData = JSON.stringify(body);
    }

    httpRequest.request(
      url,
      {
        method: method,
        header: headers,
        extraData: extraData,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      },
      (err: BusinessError, data: http.HttpResponse) => {
        httpRequest.destroy();

        if (err) {
          reject(new Error('网络请求失败，请检查网络连接'));
          return;
        }

        try {
          const raw = data.result as string;
          const resp: ApiResponse<T> = JSON.parse(raw);

          if (resp.code === 200) {
            resolve(resp.data as T);
          } else if (resp.code === 401) {
            AppStorage.delete('token');
            AppStorage.delete('member');
            try {
              router.replaceUrl({ url: 'pages/Login' });
            } catch (_) {}
            reject(new Error('登录已过期，请重新登录'));
          } else {
            reject(new Error(resp.msg || '请求失败'));
          }
        } catch (parseErr) {
          reject(new Error('数据解析失败'));
        }
      }
    );
  });
}

export async function get<T>(path: string): Promise<T> {
  return request<T>(http.RequestMethod.GET, path);
}

export async function post<T>(path: string, body: object): Promise<T> {
  return request<T>(http.RequestMethod.POST, path, body);
}

export async function put<T>(path: string, body: object): Promise<T> {
  return request<T>(http.RequestMethod.PUT, path, body);
}

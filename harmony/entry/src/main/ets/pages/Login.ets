import router from '@ohos.router';
import { post } from '../utils/HttpUtil';

class LoginReqBody {
  phone: string = '';
  password: string = '';
}

interface LoginMemberInfo {
  id: number;
  name: string;
  phone: string;
  status: number;
  role: number;
}

interface LoginCoachInfo {
  id: number;
  name: string;
  phone: string;
  specialty: string;
  status: number;
}

class LoginResponse {
  token: string = '';
  member: LoginMemberInfo | null = null;
  coach: LoginCoachInfo | null = null;
  coachId: number = 0;
}

@Entry
@Component
struct Login {
  @State phone: string = '';
  @State password: string = '';
  @State loading: boolean = false;

  build() {
    Column() {
      Scroll() {
        Column() {
          // Logo 区域
          Column() {
            Column() {
              Image($r('app.media.foreground'))
                .width(72)
                .height(72)
                .borderRadius(20);
            }
            .width(88)
            .height(88)
            .backgroundColor(Color.White)
            .borderRadius(22)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .shadow({
              radius: 16,
              color: 'rgba(0,0,0,0.15)',
              offsetX: 0,
              offsetY: 4
            });

            Text('健身管家')
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .margin({ top: 16 });

            Text('会员端')
              .fontSize(14)
              .fontColor('rgba(255,255,255,0.7)')
              .margin({ top: 4 });
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 56, bottom: 32 });

          // 登录表单卡片
          Column() {
            Text('账号登录')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2d3436')
              .width('100%');

            Text('欢迎回来，请登录您的账号')
              .fontSize(14)
              .fontColor('#636e72')
              .width('100%')
              .margin({ top: 4, bottom: 24 });

            // 手机号
            Column() {
              Text('手机号')
                .fontSize(13)
                .fontColor('#636e72')
                .margin({ bottom: 6 });
              TextInput({ placeholder: '请输入手机号', text: this.phone })
                .type(InputType.PhoneNumber)
                .maxLength(11)
                .onChange((val: string) => { this.phone = val; })
                .backgroundColor('#f5f7fa')
                .borderRadius(12)
                .padding({ left: 16, right: 16 })
                .height(50)
                .width('100%')
                .placeholderColor('#b2bec3')
                .placeholderFont({ size: 14 });
            }
            .width('100%');

            // 密码
            Column() {
              Text('密码')
                .fontSize(13)
                .fontColor('#636e72')
                .margin({ top: 16, bottom: 6 });
              TextInput({ placeholder: '请输入密码', text: this.password })
                .type(InputType.Password)
                .onChange((val: string) => { this.password = val; })
                .backgroundColor('#f5f7fa')
                .borderRadius(12)
                .padding({ left: 16, right: 16 })
                .height(50)
                .width('100%')
                .placeholderColor('#b2bec3')
                .placeholderFont({ size: 14 });
            }
            .width('100%');

            // 登录按钮
            Button() {
              if (this.loading) {
                LoadingProgress()
                  .width(22)
                  .height(22)
                  .color(Color.White);
              } else {
                Text('登 录')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.White);
              }
            }
            .width('100%')
            .height(50)
            .borderRadius(12)
            .linearGradient({
              direction: GradientDirection.Right,
              colors: [
                ['#1a1a2e', 0.0],
                ['#0f3460', 1.0]
              ]
            })
            .margin({ top: 28 })
            .enabled(!this.loading)
            .shadow({
              radius: 8,
              color: 'rgba(15,52,96,0.3)',
              offsetX: 0,
              offsetY: 4
            })
            .onClick(() => {
              this.handleLogin();
            });

            // 注册入口
            Row() {
              Text('还没有账号？')
                .fontSize(14)
                .fontColor('#636e72');
              Text('立即注册')
                .fontSize(14)
                .fontColor('#e94560')
                .fontWeight(FontWeight.Medium)
                .onClick(() => {
                  router.pushUrl({ url: 'pages/Register' });
                });
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 24 });
          }
          .width('100%')
          .padding(24)
          .backgroundColor(Color.White)
          .borderRadius(16)
          .shadow({
            radius: 20,
            color: 'rgba(0,0,0,0.06)',
            offsetX: 0,
            offsetY: 8
          })
          .margin({ left: 24, right: 24 });
        }
        .width('100%')
        .padding({ bottom: 40 });
      }
      .width('100%')
      .layoutWeight(1);
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        ['#1a1a2e', 0.0],
        ['#0f3460', 0.35],
        ['#0f3460', 0.4],
        ['#f5f6fa', 0.42],
        ['#f5f6fa', 1.0]
      ]
    });
  }

  async handleLogin(): Promise<void> {
    if (!this.phone || this.phone.length < 11) {
      AlertDialog.show({
        title: '提示',
        message: '请输入正确的手机号',
        confirm: { value: '确定', action: () => {} }
      });
      return;
    }
    if (!this.password) {
      AlertDialog.show({
        title: '提示',
        message: '请输入密码',
        confirm: { value: '确定', action: () => {} }
      });
      return;
    }
    this.loading = true;
    try {
      let loginReq = new LoginReqBody();
      loginReq.phone = this.phone;
      loginReq.password = this.password;
      const result = await post<LoginResponse>('/auth/login', loginReq);
      if (result.member != null) {
        AppStorage.setOrCreate<string>('token', result.token);
        AppStorage.setOrCreate<object>('member', result.member as object);
        AppStorage.setOrCreate<number>('memberId', result.member.id);
        if (result.coachId > 0) {
          AppStorage.setOrCreate<number>('coachId', result.coachId);
        }
        let targetPage: string = 'pages/Index';
        if (result.member.role === 2) {
          targetPage = 'pages/CoachIndex';
        }
        try { router.replaceUrl({ url: targetPage }); } catch (_) {}
      }
    } catch (err) {
      const msg = (err as Error).message || '登录失败';
      AlertDialog.show({
        title: '提示',
        message: msg,
        confirm: { value: '确定', action: () => {} }
      });
    } finally {
      this.loading = false;
    }
  }
}

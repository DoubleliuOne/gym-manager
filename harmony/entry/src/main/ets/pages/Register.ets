import router from '@ohos.router';
import { post } from '../utils/HttpUtil';
import { RegisterRequest } from '../utils/HttpUtil';

class LoginInfo {
  phone: string = '';
  password: string = '';
}

class LoginMemberInfo {
  id: number = 0;
  name: string = '';
  phone: string = '';
  gender: number = 0;
  birthday: string | null = null;
  avatarUrl: string | null = null;
  status: number = 0;
  role: number = 0;
}

class LoginResponse {
  token: string = '';
  member: LoginMemberInfo = new LoginMemberInfo();
}

@Entry
@Component
struct Register {
  @State name: string = '';
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
                .width(60)
                .height(60)
                .borderRadius(16);
            }
            .width(76)
            .height(76)
            .backgroundColor(Color.White)
            .borderRadius(20)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .shadow({
              radius: 12,
              color: 'rgba(0,0,0,0.12)',
              offsetX: 0,
              offsetY: 4
            });

            Text('创建新账号')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .margin({ top: 14 });

            Text('开启您的健身之旅')
              .fontSize(13)
              .fontColor('rgba(255,255,255,0.6)')
              .margin({ top: 4 });
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 48, bottom: 24 });

          // 注册表单卡片
          Column() {
            Column() {
              Text('姓名')
                .fontSize(13)
                .fontColor('#636e72')
                .margin({ bottom: 6 });
              TextInput({ placeholder: '请输入姓名', text: this.name })
                .onChange((val: string) => { this.name = val; })
                .backgroundColor('#f5f7fa')
                .borderRadius(12)
                .padding({ left: 16, right: 16 })
                .height(50)
                .width('100%')
                .placeholderColor('#b2bec3')
                .placeholderFont({ size: 14 });
            }
            .width('100%');

            Column() {
              Text('手机号')
                .fontSize(13)
                .fontColor('#636e72')
                .margin({ top: 16, bottom: 6 });
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

            Column() {
              Text('密码')
                .fontSize(13)
                .fontColor('#636e72')
                .margin({ top: 16, bottom: 6 });
              TextInput({ placeholder: '请设置密码（至少6位）', text: this.password })
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

            Button() {
              if (this.loading) {
                LoadingProgress()
                  .width(22)
                  .height(22)
                  .color(Color.White);
              } else {
                Text('注 册')
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
              this.handleRegister();
            });

            Row() {
              Text('已有账号？')
                .fontSize(14)
                .fontColor('#636e72');
              Text('立即登录')
                .fontSize(14)
                .fontColor('#e94560')
                .fontWeight(FontWeight.Medium)
                .onClick(() => {
                  router.back();
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

  async handleRegister(): Promise<void> {
    if (!this.name) {
      AlertDialog.show({
        title: '提示',
        message: '请输入姓名',
        confirm: { value: '确定', action: () => {} }
      });
      return;
    }
    if (!this.phone || this.phone.length < 11) {
      AlertDialog.show({
        title: '提示',
        message: '请输入正确的手机号',
        confirm: { value: '确定', action: () => {} }
      });
      return;
    }
    if (!this.password || this.password.length < 6) {
      AlertDialog.show({
        title: '提示',
        message: '密码至少6位',
        confirm: { value: '确定', action: () => {} }
      });
      return;
    }

    this.loading = true;
    let req: RegisterRequest = new RegisterRequest();
    req.phone = this.phone;
    req.password = this.password;
    req.name = this.name;

    try {
      await post<null>('/auth/register', req);

      let loginReq: LoginInfo = new LoginInfo();
      loginReq.phone = this.phone;
      loginReq.password = this.password;

      const loginResult = await post<LoginResponse>('/auth/login', loginReq);

      AppStorage.setOrCreate<string>('token', loginResult.token);
      AppStorage.setOrCreate<object>('member', loginResult.member as object);
      AppStorage.setOrCreate<number>('memberId', loginResult.member.id);

      try {
        router.replaceUrl({ url: 'pages/ProfileSetup' });
      } catch (_) {}
    } catch (err) {
      const msg = (err as Error).message || '注册失败';
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

import router from '@ohos.router';
import { post } from '../utils/HttpUtil';

class ProfileSetupInfo {
  memberId: number = 0;
  role: string = "";
  gender: number = 0;
  birthday: string = "";
  specialty: string = "";
}

class ProfileSetupMemberInfo {
  id: number = 0;
  name: string = "";
  phone: string = "";
  gender: number = 0;
  birthday: string | null = null;
  avatarUrl: string | null = null;
  status: number = 0;
  role: number = 0;
}

class ProfileSetupResponse {
  token: string = "";
  member: ProfileSetupMemberInfo = new ProfileSetupMemberInfo();
}


@Entry
@Component
struct ProfileSetup {
  @State memberId: number = 0;
  @State memberName: string = "";
  @State memberPhone: string = "";
  @State role: string = "member";
  @State gender: number = 0;
  @State selectedDate: Date = new Date(2000, 0, 1);
  @State birthday: string = "";
  @State specialty: string = "";
  @State loading: boolean = false;
  @State currentStep: number = 1;

  aboutToAppear(): void {
    this.checkAuth();
  }

  checkAuth(): void {
    const token = AppStorage.get<string>("token");
    if (!token) {
      try { router.replaceUrl({ url: "pages/Login" }); } catch (_) {}
      return;
    }
    const mid = AppStorage.get<number>("memberId");
    const memberData = AppStorage.get<object>("member");
    if (mid) {
      this.memberId = mid;
    }
    if (memberData) {
      const m = memberData as Record<string, Object>;
      this.memberName = (m["name"] as string) ?? "";
      this.memberPhone = (m["phone"] as string) ?? "";
    }
  }

  async handleSave(): Promise<void> {
    this.loading = true;
    try {
      let req: ProfileSetupInfo = new ProfileSetupInfo();
      req.memberId = this.memberId;
      req.role = this.role;

      if (this.role === "coach") {
        req.specialty = this.specialty;
      } else {
        req.gender = this.gender;
        req.birthday = this.birthday;
      }

      const result = await post<ProfileSetupResponse>("/auth/profile-setup", req);

      if (result.member) {
        AppStorage.setOrCreate<object>("member", result.member as object);
      }

      let targetPage: string = "pages/Index";
      if (result.member && result.member.role === 2) {
        targetPage = "pages/CoachIndex";
      }

      AlertDialog.show({
        title: "完成",
        message: "资料已保存，即将进入主页",
        confirm: {
          value: "确定",
          action: () => {
            try { router.replaceUrl({ url: targetPage }); } catch (_) {}
          }
        }
      });
    } catch (err) {
      const msg = (err as Error).message || "保存失败";
      AlertDialog.show({
        title: "提示",
        message: msg,
        confirm: { value: "确定", action: () => {} }
      });
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text("完善个人资料")
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor("#ffffff");
      }
      .width("100%")
      .height(56)
      .padding({ left: 20, right: 20 })
      .linearGradient({
        direction: GradientDirection.Right,
        colors: [
          ['#1a1a2e', 0.0],
          ['#0f3460', 1.0]
        ]
      });

      Scroll() {
        Column() {
          // 步骤指示
          Row() {
            Column() {
              Column() {
                Text('1')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White);
              }
              .width(28)
              .height(28)
              .backgroundColor('#1a1a2e')
              .borderRadius(14)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center);

              Text('选择身份')
                .fontSize(11)
                .fontColor('#1a1a2e')
                .fontWeight(FontWeight.Medium)
                .margin({ top: 4 });
            }
            .alignItems(HorizontalAlign.Center);

            Column()
              .layoutWeight(1)
              .height(1)
              .backgroundColor('#e0e0e0')
              .margin({ left: 8, right: 8 });

            Column() {
              Column() {
                Text('2')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White);
              }
              .width(28)
              .height(28)
              .backgroundColor('#1a1a2e')
              .borderRadius(14)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center);

              Text('填写信息')
                .fontSize(11)
                .fontColor('#1a1a2e')
                .fontWeight(FontWeight.Medium)
                .margin({ top: 4 });
            }
            .alignItems(HorizontalAlign.Center);
          }
          .width('100%')
          .padding({ left: 32, right: 32, bottom: 20 });

          // 身份选择卡片
          Column() {
            Text("请选择您的身份")
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor("#1a1a2e")
              .margin({ bottom: 12 });

            Row() {
              Column() {
                Column() {
                  Text('👤')
                    .fontSize(28);
                }
                .width(48)
                .height(48)
                .backgroundColor('#f5f7fa')
                .borderRadius(24)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center);

                Text("客户")
                  .fontSize(16)
                  .fontWeight(this.role === "member" ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(this.role === "member" ? "#ffffff" : "#1a1a2e")
                  .margin({ top: 8 });
                Text("预约课程、使用会员卡")
                  .fontSize(11)
                  .fontColor(this.role === "member" ? "rgba(255,255,255,0.7)" : "#999999")
                  .margin({ top: 2 });
              }
              .padding(16)
              .backgroundColor(this.role === "member" ? "#1a1a2e" : "#ffffff")
              .borderRadius(14)
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => { this.role = "member"; })
              .shadow(this.role === "member" ? {
                radius: 10,
                color: 'rgba(26,26,46,0.2)',
                offsetX: 0,
                offsetY: 4
              } : { radius: 0 });

              Column() {
                Column() {
                  Text('🏋️')
                    .fontSize(28);
                }
                .width(48)
                .height(48)
                .backgroundColor('#f5f7fa')
                .borderRadius(24)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center);

                Text("教练")
                  .fontSize(16)
                  .fontWeight(this.role === "coach" ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(this.role === "coach" ? "#ffffff" : "#1a1a2e")
                  .margin({ top: 8 });
                Text("管理课程、带课教学")
                  .fontSize(11)
                  .fontColor(this.role === "coach" ? "rgba(255,255,255,0.7)" : "#999999")
                  .margin({ top: 2 });
              }
              .padding(16)
              .backgroundColor(this.role === "coach" ? "#1a1a2e" : "#ffffff")
              .borderRadius(14)
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
              .margin({ left: 12 })
              .onClick(() => { this.role = "coach"; })
              .shadow(this.role === "coach" ? {
                radius: 10,
                color: 'rgba(26,26,46,0.2)',
                offsetX: 0,
                offsetY: 4
              } : { radius: 0 });
            }
            .width("100%")
            .margin({ top: 8 });
          }
          .width("100%")
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(14)
          .shadow({
            radius: 10,
            color: 'rgba(0,0,0,0.04)',
            offsetX: 0,
            offsetY: 4
          });

          if (this.role === "member") {
            Column() {
              Text("个人信息")
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor("#1a1a2e")
                .margin({ bottom: 16 });

              Row() {
                Text("姓名")
                  .fontSize(14)
                  .fontColor("#666666");
                Text(this.memberName)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor("#1a1a2e")
                  .layoutWeight(1)
                  .textAlign(TextAlign.End);
              }
              .width("100%")
              .margin({ bottom: 10 });

              Row() {
                Text("手机号")
                  .fontSize(14)
                  .fontColor("#666666");
                Text(this.memberPhone)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor("#1a1a2e")
                  .layoutWeight(1)
                  .textAlign(TextAlign.End);
              }
              .width("100%")
              .margin({ bottom: 16 });

              Column()
                .width("100%")
                .height(1)
                .backgroundColor("#f0f0f0")
                .margin({ bottom: 16 });

              Text("性别")
                .fontSize(14)
                .fontColor("#666666")
                .margin({ bottom: 10 });

              Row() {
                Column() {
                  Text('♂')
                    .fontSize(20)
                    .margin({ bottom: 4 });
                  Text("男")
                    .fontSize(14)
                    .fontColor(this.gender === 1 ? "#ffffff" : "#1a1a2e");
                }
                .padding(16)
                .backgroundColor(this.gender === 1 ? "#1a1a2e" : "#f5f7fa")
                .borderRadius(12)
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)
                .onClick(() => { this.gender = 1; })
                .shadow(this.gender === 1 ? {
                  radius: 6,
                  color: 'rgba(26,26,46,0.15)',
                  offsetX: 0,
                  offsetY: 3
                } : { radius: 0 });

                Column() {
                  Text('♀')
                    .fontSize(20)
                    .margin({ bottom: 4 });
                  Text("女")
                    .fontSize(14)
                    .fontColor(this.gender === 2 ? "#ffffff" : "#1a1a2e");
                }
                .padding(16)
                .backgroundColor(this.gender === 2 ? "#1a1a2e" : "#f5f7fa")
                .borderRadius(12)
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)
                .margin({ left: 12 })
                .onClick(() => { this.gender = 2; })
                .shadow(this.gender === 2 ? {
                  radius: 6,
                  color: 'rgba(26,26,46,0.15)',
                  offsetX: 0,
                  offsetY: 3
                } : { radius: 0 });
              }
              .width("100%")
              .margin({ bottom: 20 });

              Text("出生日期")
                .fontSize(14)
                .fontColor("#666666")
                .margin({ bottom: 10 });

              DatePicker({
                start: new Date("1900-01-01"),
                end: new Date(),
                selected: this.selectedDate
              })
              .onChange((value: DatePickerResult) => {
                let year: number = value.year ?? 2000;
                let month: number = value.month ?? 1;
                let day: number = value.day ?? 1;
                this.selectedDate = new Date(year, month - 1, day);
                let mStr: string = month < 10 ? "0" + month : "" + month;
                let dStr: string = day < 10 ? "0" + day : "" + day;
                this.birthday = year + "-" + mStr + "-" + dStr;
              });
            }
            .width("100%")
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(14)
            .margin({ top: 12 })
            .shadow({
              radius: 10,
              color: 'rgba(0,0,0,0.04)',
              offsetX: 0,
              offsetY: 4
            });
          } else {
            Column() {
              Column() {
                Row() {
                  Column() {
                    Column()
                      .width(56)
                      .height(56)
                      .backgroundColor('#e0e0e0')
                      .borderRadius(28);

                    Text(this.memberName)
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor("#1a1a2e")
                      .margin({ top: 8 });
                    Text(this.memberPhone)
                      .fontSize(13)
                      .fontColor("#999999")
                      .margin({ top: 2 });
                  }
                  .alignItems(HorizontalAlign.Center)
                  .width('100%');
                }
                .width("100%");
              }
              .padding(16)
              .backgroundColor("#f8f9fa")
              .borderRadius(12)
              .width("100%");

              Text("教学专长")
                .fontSize(14)
                .fontColor("#666666")
                .margin({ top: 20, bottom: 8 });

              TextArea({ placeholder: "请输入您的专长领域，如：瑜伽、普拉提、动感单车等", text: this.specialty })
                .onChange((val: string) => { this.specialty = val; })
                .backgroundColor("#f5f7fa")
                .borderRadius(12)
                .padding(16)
                .height(100)
                .width("100%")
                .placeholderColor('#b2bec3')
                .placeholderFont({ size: 14 });
            }
            .width("100%")
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(14)
            .margin({ top: 12 })
            .shadow({
              radius: 10,
              color: 'rgba(0,0,0,0.04)',
              offsetX: 0,
              offsetY: 4
            });
          }

          Button() {
            if (this.loading) {
              LoadingProgress().width(22).height(22).color(Color.White);
            } else {
              Text("保存并进入").fontSize(16).fontWeight(FontWeight.Medium).fontColor(Color.White);
            }
          }
          .width("100%")
          .height(50)
          .borderRadius(12)
          .linearGradient({
            direction: GradientDirection.Right,
            colors: [
              ['#1a1a2e', 0.0],
              ['#0f3460', 1.0]
            ]
          })
          .margin({ top: 24 })
          .enabled(!this.loading)
          .shadow({
            radius: 8,
            color: 'rgba(15,52,96,0.3)',
            offsetX: 0,
            offsetY: 4
          })
          .onClick(() => { this.handleSave(); });
        }
        .width("100%")
        .padding(16);
      }
      .width("100%")
      .layoutWeight(1);
    }
    .width("100%")
    .height("100%")
    .backgroundColor("#f5f6fa");
  }
}


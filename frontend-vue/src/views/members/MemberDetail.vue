<template>
  <div>
    <a-space style="margin-bottom: 16px">
      <a-button @click="$router.push('/members')">
        <template #icon><arrow-left-outlined /></template>返回
      </a-button>
    </a-space>
    <a-card title="会员信息">
      <a-descriptions :column="2" bordered size="small">
        <a-descriptions-item label="ID">{{ member?.id }}</a-descriptions-item>
        <a-descriptions-item label="姓名">{{ member?.name }}</a-descriptions-item>
        <a-descriptions-item label="手机号">{{ member?.phone }}</a-descriptions-item>
        <a-descriptions-item label="性别">{{ member?.gender === 1 ? "男" : member?.gender === 2 ? "女" : "-" }}</a-descriptions-item>
        <a-descriptions-item label="生日">{{ member?.birthday || "-" }}</a-descriptions-item>
        <a-descriptions-item label="状态">
          <a-tag :color="member?.status === 0 ? 'green' : 'red'">
            {{ member?.status === 0 ? "正常" : "冻结" }}
          </a-tag>
        </a-descriptions-item>
        <a-descriptions-item label="注册时间">{{ member?.createdAt }}</a-descriptions-item>
      </a-descriptions>
    </a-card>
    <a-card title="会员卡" style="margin-top: 16px">
      <a-table rowKey="id" :columns="cardColumns" :dataSource="cards" :pagination="false" size="small">
        <template #bodyCell="{ column, record }">
          <template v-if="column.dataIndex === 'remainingCount'">
            {{ record.remainingCount === -1 ? "不限次" : record.remainingCount }}
          </template>
          <template v-else-if="column.dataIndex === 'status'">
            <a-tag :color="statusColor(record.status)">{{ statusLabel(record.status) }}</a-tag>
          </template>
        </template>
      </a-table>
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from "vue";
import { useRoute } from "vue-router";
import { ArrowLeftOutlined } from "@ant-design/icons-vue";
import { memberApi } from "../../api/members";
import type { MemberInfo, MemberCard } from "../../api/members";

const route = useRoute();
const member = ref<MemberInfo | null>(null);
const cards = ref<MemberCard[]>([]);

const cardColumns = [
  { title: "卡ID", dataIndex: "id", key: "id", width: 60 },
  { title: "模板ID", dataIndex: "templateId", key: "templateId", width: 80 },
  { title: "开始日期", dataIndex: "startDate", key: "startDate" },
  { title: "结束日期", dataIndex: "endDate", key: "endDate" },
  { title: "剩余次数", dataIndex: "remainingCount", key: "remainingCount", width: 90 },
  { title: "状态", dataIndex: "status", key: "status", width: 80 },
];

const statusMap: Record<number, [string, string]> = {
  0: ["正常", "green"], 1: ["过期", "red"], 2: ["用完", "orange"],
};

function statusColor(s: number) { return (statusMap[s] || ["未知", "default"])[1]; }
function statusLabel(s: number) { return (statusMap[s] || ["未知", "default"])[0]; }

onMounted(async () => {
  const id = Number(route.params.id);
  const [mRes, cRes] = await Promise.all([memberApi.getById(id), memberApi.getCards(id)]);
  member.value = mRes.data;
  cards.value = cRes.data;
});
</script>

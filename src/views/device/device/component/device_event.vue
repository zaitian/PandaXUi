<template>
  <div style="margin: 10px">
    <el-card shadow="always">
      <!-- 查询 -->
      <el-form
          :model="state.queryParams"
          ref="queryForm"
          :inline="true"
          label-width="68px"
      >
        <el-form-item label="告警类型" prop="state">
          <el-select v-model="state.queryParams.type" placeholder="告警类型" style="width: 200px" clearable>
            <el-option label="信息" value="info"/>
            <el-option label="告警" value="alarm"/>
            <el-option label="故障" value="fault"/>
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleQuery">
            <SvgIcon name="elementSearch" />搜索</el-button>
          <el-button @click="resetQuery">
            <SvgIcon name="elementRefresh" />
            重置
          </el-button>
        </el-form-item>
      </el-form>
    </el-card>
    <el-card class="box-card">
      <template #header>
        <div class="card-header">
          <span class="card-header-text">事件列表</span>
        </div>
      </template>
      <el-table
          v-loading="state.loading"
          border
          :data="state.tableData"
      >
        <el-table-column label="事件名称" align="center" prop="name"/>
        <el-table-column label="事件类型" align="center" prop="type">
          <template #default="scope">
            <el-tag
                :type="scope.row.type === 'info' ? 'info' : scope.row.type === 'alarm' ? 'danger' : 'warning'"
                disable-transitions
            >{{ scope.row.type ==='info'? "信息": scope.row.type ==='alarm' ? '告警': "故障" }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="事件时间" align="center" prop="ts">
          <template #default="scope">
            {{ dateStrFormat(scope.row.ts) }}
          </template>
        </el-table-column>
        <el-table-column
            label="操作"
            align="center"
            class-name="small-padding fixed-width"
        >
          <template #default="scope">
            <el-popover  placement="left">
              <template #reference>
                <el-button type="primary" circle ><SvgIcon name="elementStar"/></el-button>
              </template>
              <div>
                <el-button text type="primary" @click="onOpenEvent(scope.row)">
                  <SvgIcon name="elementView"/>
                  查看
                </el-button>
              </div>
            </el-popover>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
    <el-dialog v-model="state.isShowDialog" width="769px" title="事件数据" center draggable>
      <div class="json-viewer">
        <pre>{{ state.content }}</pre>
      </div>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="state.isShowDialog = false">取 消</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script lang="ts" setup>
import { onMounted, reactive} from "vue";
import {getDeviceEvent} from "@/api/device/device";

const props:any = defineProps({
  rowData: {
    type: Object,
  },
})

const state = reactive({
  // 遮罩层
  loading: false,
  // 表格数据
  tableData: [],
  queryParams: {
    // 页码
    pageNum: 1,
    // 每页大小
    pageSize: 10,
    deviceId: "",  //父设备Id
    type: "",
  },
  isShowDialog: false,
  content: "",
});
// 查询列表
const handleQuery = () => {
  state.loading = true;
  state.queryParams.deviceId = props.rowData.id
  getDeviceEvent(state.queryParams).then((response:any) => {
    if (response.code === 200) {
      state.tableData = response.data;
    }
    state.loading = false;
  });
};

const resetQuery = () => {
  state.queryParams.type = "";
  handleQuery();
};


const onOpenEvent = (row: object) => {
  state.isShowDialog = true
  state.content = row.content
}


onMounted(()=>{
  handleQuery()
})
</script>
<style scoped>
.json-viewer {
  height: 400px;
  font-family: monospace;
  color: #000000d9;
  font-size: 18px;
  overflow: auto;
  white-space: nowrap;
}
</style>

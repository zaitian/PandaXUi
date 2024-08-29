<template>
	<el-container class="layout-container flex-center layout-backtop">
		<Header />
		<Main />
		<el-backtop :right="100" :bottom="100" />
	</el-container>
</template>

<script lang="ts">
import Header from '@/layout/component/header.vue';
import Main from '@/layout/component/main.vue';
export default {
	name: 'layoutTransverse',
	components: { Header, Main },
};
</script>

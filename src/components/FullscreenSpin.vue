<template>
  <div class="fullscreen-spin" :class="{ 'mask': mask }" v-if="loading">
    <div class="spin">
      <div class="spinner" :style="{ borderColor: themeColor, borderTopColor: 'transparent' }"></div>
      <div class="text" :style="{ color: themeColor }">{{tip}}</div>
    </div>
  </div>
</template>

<script lang="ts" setup>
withDefaults(defineProps<{
  loading?: boolean
  mask?: boolean
  tip?: string
}>(), {
  loading: false,
  mask: true,
  tip: '',
})

// 直接使用主题色，确保从一开始就正确显示
const themeColor = '#69b8c5'
</script>

<style lang="scss" scoped>
.fullscreen-spin {
  position: fixed;
  top: 0;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 100;
  display: flex;
  justify-content: center;
  align-items: center;

  &.mask {
    background-color: rgba($color: #f1f1f1, $alpha: .7);
  }
}
.spin {
  width: 200px;
  height: 200px;
  position: fixed;
  top: 50%;
  left: 50%;
  margin-top: -100px;
  margin-left: -100px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}
.spinner {
  width: 36px;
  height: 36px;
  border: 3px solid;
  border-radius: 50%;
  animation: spinner .8s linear infinite;
  box-sizing: border-box;
}
.text {
  margin-top: 20px;
}
@keyframes spinner {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}
</style>
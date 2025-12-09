<template>
  <div class="pptist-editor">
    <EditorHeader class="layout-header" />
    <div class="layout-content">
      <Thumbnails class="layout-content-left" />
      <div class="layout-content-center">
        <Canvas class="center-body" :style="{ height: '100%' }" />
      </div>
    </div>
  </div>

</template>

<script lang="ts" setup>
import EditorHeader from './EditorHeader/index.vue'
import Canvas from './Canvas/index.vue'
import Thumbnails from './Thumbnails/index.vue'
</script>

<style lang="scss" scoped>
.pptist-editor {
  height: 100%;
}
.layout-header {
  height: 40px;
}
.layout-content {
  height: calc(100% - 40px);
  display: flex;
}
.layout-content-left {
  width: 160px;
  height: 100%;
  flex-shrink: 0;
}
.layout-content-center {
  width: calc(100% - 160px);
}
</style>
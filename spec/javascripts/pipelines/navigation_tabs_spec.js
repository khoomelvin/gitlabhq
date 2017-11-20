import Vue from 'vue';
import navigationTabs from '~/pipelines/components/navigation_tabs.vue';
import mountComponent from '../helpers/vue_mount_component_helper';

describe('navigation tabs pipeline component', () => {
  let vm;
  let Component;
  let data;

  beforeEach(() => {
    data = [
      {
        name: 'All',
        scope: 'all',
        count: 1,
        isActive: true,
      },
      {
        name: 'Pending',
        scope: 'pending',
        count: 0,
        isActive: false,
      },
      {
        name: 'Running',
        scope: 'running',
        isActive: false,
      },
    ];

    Component = Vue.extend(navigationTabs);
    vm = mountComponent(Component, { tabs: data });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render tabs', () => {
    expect(vm.$el.querySelectorAll('li').length).toEqual(data.length);
  });

  it('should render active tab', () => {
    expect(vm.$el.querySelector('.active .js-pipelines-tab-all')).toBeDefined();
  });

  it('should render badge', () => {
    expect(vm.$el.querySelector('.js-pipelines-tab-all .badge').textContent.trim()).toEqual('1');
    expect(vm.$el.querySelector('.js-pipelines-tab-pending .badge').textContent.trim()).toEqual('0');
  });

  it('should not render badge', () => {
    expect(vm.$el.querySelector('.js-pipelines-tab-running .badge')).toEqual(null);
  });
});

<div x-data="{ 
        barOpen: $persist(false).as('wave.adminBarOPen'),
         visible: false, 
         iframeOpen: false,
         buttonCollapsed: false,
         section: '',
         iframeURL: 'about:blank',
    }" wire:ignore x-init="

        $watch('iframeOpen', (newValue) => {
            if (!newValue) {
                section = '';
                iframeURL='about:blank';
            }
        });
    "
    x-on:keyup.escape.window="iframeOpen=false" 
    class="fixed top-0 left-0 z-50 text-white isolate dark:text-gray-900" x-cloak>
    
    @include('admin-bar::partials.tab')
    @include('admin-bar::partials.bar')
    
    <div x-show="iframeOpen" class="relative z-20 flex items-center justify-center w-dvw h-dvh">
        <div :class="{ 'pl-[42px] py-1 pr-5': barOpen }" class="absolute w-full h-full">
            <div class="h-full p-2 rounded-md bg-gray-900/5 dark:bg-gray-100/30 ring-1 ring-inset ring-gray-900/20 dark:ring-gray-100/10 lg:rounded-xl lg:p-2.5">
            {{-- <div class="w-full h-full bg-green-100 border-4 border-gray-900 rounded-md"></div> --}}
            <iframe :src="iframeURL" class="w-full h-full bg-gray-900 rounded-md dark:bg-gray-50" border="0"></iframe>
            </div>
        </div>
    </div>
    <div x-show="iframeOpen" x-on:click="iframeOpen=false" class="fixed inset-0 z-10 w-full h-full bg-black opacity-10"></div>
</div>

<div 
    x-show="barOpen" 
    x-transition:enter="transition ease-out duration-300" 
    x-transition:enter-start="opacity-0 -translate-x-full" 
    x-transition:enter-end="translate-x-0" 
    x-transition:leave="transition ease-in duration-300" 
    x-transition:leave-start="translate-x-0" 
    x-transition:leave-end="-translate-x-full" 
    class="fixed top-0 left-0 z-30 h-dvh"
    >
    <div 
        class="h-full max-h-full p-1 duration-300 ease-out">
        <div class="w-8 pb-1 rounded-md bg-gray-950/90 backdrop-blur-xl dark:bg-gray-50/90">

            <div class="flex items-center justify-center w-8 h-8 overflow-hidden group">
                <button :class="{ 'translate-x-full' : iframeOpen }" x-on:click="barOpen=false" class="flex items-center justify-center w-8 h-8 duration-300 ease-out">
                    <svg class="relative flex-shrink-0 w-4 h-4 duration-300 ease-out opacity-60 group-hover:opacity-100" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M3.74963 12H20.2496M3.74963 12L10.2496 18.25M3.74963 12L10.2496 5.75" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
                </button>
                <button :class="{ '-translate-x-full' : !iframeOpen }" x-on:click="iframeOpen=false" class="absolute flex items-center justify-center w-8 h-8 duration-300 ease-out">
                    <svg class="relative flex-shrink-0 w-4 h-4 duration-300 ease-out opacity-60 group-hover:opacity-100" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
                </button>
            </div>

            <button x-on:click="iframeURL='https://devdojo.com/wave/docs/getting-started'; if(section=='docs' && iframeOpen){ iframeOpen=false; } else { iframeOpen=true; } section='docs';" :class="{ 'text-white dark:text-gray-950' : section == 'docs', 'dark:text-gray-950/60 dark:hover:text-gray-950 text-white/70 hover:text-white' : section != 'docs' }" class="relative group">
                <span class="relative z-20 flex items-center justify-center w-8 h-8 dark:group-hover:bg-gradient-to-r dark:group-hover:from-gray-50 dark:group-hover:to-white group-hover:bg-gradient-to-r from-gray-950 to-gray-800">
                    <svg class="w-[18px] h-[18px] group-hover:translate-x-0.5 ease-out duration-300" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256"><path fill="none" d="M0 0h256v256H0z"/><path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16" d="M112 112h64M112 144h64"/><rect width="176" height="176" x="40" y="40" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16" rx="8"/><path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16" d="M80 40v176"/></svg>
                </span>
                <span class="absolute top-0 z-10 flex items-center object-right h-8 pl-2 pr-3 text-xs duration-300 ease-out translate-x-6 bg-gray-800 rounded-r opacity-0 pointer-events-none dark:bg-white group-hover:pointer-events-auto group-hover:translate-x-7 group-hover:opacity-100">Docs</span>
            </button>
            <button x-on:click="iframeURL='/admin'; if(section=='admin' && iframeOpen){ iframeOpen=false; } else { iframeOpen=true; }  section='admin';" :class="{ 'text-white dark:text-gray-950' : section == 'admin', 'dark:text-gray-950/60 dark:hover:text-gray-950 text-white/70 hover:text-white' : section != 'admin' }" class="relative group">
                <span class="relative z-20 flex items-center justify-center w-8 h-8 dark:group-hover:bg-gradient-to-r dark:group-hover:from-gray-50 dark:group-hover:to-white group-hover:bg-gradient-to-r from-gray-950 to-gray-800">
                    <svg class="w-[18px] h-[18px] group-hover:translate-x-0.5 ease-out duration-300" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M5.45493 16.25H18.5426M17.1759 10.1313L18.5908 8.8956C19.3333 8.24713 20.467 8.95066 20.2155 9.90386L18.1431 17.7602C17.9114 18.6382 17.1173 19.25 16.2092 19.25L7.79155 19.25C6.88313 19.25 6.08881 18.6378 5.85748 17.7593L3.78904 9.9044C3.538 8.95108 4.67202 8.24805 5.41423 8.89687L6.82353 10.1289C7.94048 11.1053 9.69439 10.5684 10.0735 9.1341L11.0328 5.50402C11.2951 4.51141 12.704 4.51134 12.9664 5.50391L13.9267 9.13617C14.3058 10.57 16.0589 11.1069 17.1759 10.1313Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
                </span>
                <span class="absolute top-0 z-10 flex items-center object-right h-8 pl-2 pr-3 text-xs duration-300 ease-out translate-x-6 bg-gray-800 rounded-r opacity-0 pointer-events-none dark:bg-white group-hover:pointer-events-auto group-hover:translate-x-7 group-hover:opacity-100">Admin</span>
            </button>
            <button x-on:click="iframeURL='/admin/media'; if(section=='media' && iframeOpen){ iframeOpen=false; } else { iframeOpen=true; }  section='media';" :class="{ 'text-white dark:text-gray-950' : section == 'media', 'dark:text-gray-950/60 dark:hover:text-gray-950 text-white/70 hover:text-white' : section != 'media' }" class="relative group">
                <span class="relative z-20 flex items-center justify-center w-8 h-8 dark:group-hover:bg-gradient-to-r dark:group-hover:from-gray-50 dark:group-hover:to-white group-hover:bg-gradient-to-r from-gray-950 to-gray-800">
                    <svg class="w-[18px] h-[18px] group-hover:translate-x-0.5 ease-out duration-300" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256"><path fill="none" d="M0 0h256v256H0z"/><rect width="144" height="144" x="72" y="40" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16" rx="8"/><circle cx="120" cy="88" r="16" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"/><path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16" d="M184 184v24a8 8 0 0 1-8 8H48a8 8 0 0 1-8-8V80a8 8 0 0 1 8-8h24"/><path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16" d="m96.69 184 77.65-77.66a8 8 0 0 1 11.32 0L216 136.69"/></svg>
                </span>
                <span class="absolute top-0 z-10 flex items-center object-right h-8 pl-2 pr-3 text-xs duration-300 ease-out translate-x-6 bg-gray-800 rounded-r opacity-0 pointer-events-none dark:bg-white group-hover:pointer-events-auto group-hover:translate-x-7 group-hover:opacity-100">Media</span>
            </button>
            <a href="/profile/{{ auth()->user()->username }}" :class="{ 'text-white dark:text-gray-950' : '{{ Request::is('profile/' . auth()->user()->username ) }}', 'text-white/70 hover:text-white dark:text-gray-950/60 dark:hover:text-gray-950' : '{{ !Request::is('profile/' . auth()->user()->username ) }}' }" class="relative block group">
                <span class="relative z-20 flex items-center justify-center w-8 h-8 group-hover:bg-gradient-to-r from-gray-950 dark:group-hover:bg-gradient-to-r dark:group-hover:from-gray-50 dark:group-hover:to-white to-gray-800">
                    <svg class="w-[18px] h-[18px] group-hover:translate-x-0.5 ease-out duration-300" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256"><path fill="none" d="M0 0h256v256H0z"/><circle cx="128" cy="128" r="96" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"/><circle cx="128" cy="120" r="40" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"/><path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16" d="M63.8 199.37a72 72 0 0 1 128.4 0"/></svg>
                </span>
                <span class="absolute top-0 z-10 flex items-center object-right h-8 pl-2 pr-3 text-xs duration-300 ease-out translate-x-6 bg-gray-800 rounded-r opacity-0 pointer-events-none group-hover:pointer-events-auto dark:bg-white group-hover:translate-x-7 group-hover:opacity-100">Profile</span>
            </a>

            <form method="POST" action="{{ route('logout') }}" class="w-full">
                @csrf
                <button onclick="event.preventDefault(); this.closest('form').submit();" :class="{ 'text-white dark:text-gray-950' : section == 'media', 'dark:text-gray-950/60 dark:hover:text-gray-950 text-white/70 hover:text-white' : section != 'media' }" class="relative group">
                    <span class="relative z-20 flex items-center justify-center w-8 h-8 dark:group-hover:bg-gradient-to-r dark:group-hover:from-gray-50 dark:group-hover:to-white group-hover:bg-gradient-to-r from-gray-950 to-gray-800">
                        <svg class="w-[18px] h-[18px] group-hover:translate-x-0.5 ease-out duration-300" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256"><path fill="none" d="M0 0h256v256H0z"/><path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16" d="M112 40H48v176h64M112 128h112M184 88l40 40-40 40"/></svg>
                    </span>
                    <span class="absolute top-0 z-10 flex items-center flex-shrink-0 object-right h-8 pl-2 pr-3 text-xs duration-300 ease-out translate-x-6 bg-gray-800 rounded-r opacity-0 pointer-events-none dark:bg-white group-hover:pointer-events-auto group-hover:translate-x-7 group-hover:opacity-100">Logout</span>
                </button>
            </form>
        </div>
    </div>
</div>
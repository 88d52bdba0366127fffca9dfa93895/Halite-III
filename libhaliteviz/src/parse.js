import parseWorker from "worker-loader!./parseWorker.js";
import {TextDecoder} from 'text-encoding';

export function parseReplay(buffer) {
    return new Promise((resolve, reject) => {
        try {
            const startTime = Date.now();
            const worker = new parseWorker();
            worker.onmessage = function (e) {
                const inflated = e.data;
                const inflatedTime = Date.now();
                const arr = new Uint8Array(inflated);
                if (arr[0] === 0) {
                    // Decompression failed
                    reject();
                    return;
                }
                const decoded = new TextDecoder("utf-8").decode(arr);
                const replay = JSON.parse(decoded);
                const finishTime = Date.now();
                console.info(`Decoded compressed replay in ${finishTime - startTime}ms, inflating took ${inflatedTime - startTime}ms, decoding took ${finishTime - inflatedTime}ms.`);
                resolve(replay);
            };
            worker.postMessage(buffer, [buffer]);
            if (buffer.byteLength) {
                console.warn("Transferrables not supported, could not decode without copying data!");
            }
        }
        catch (e) {
            console.error(e);
            resolve(msgpack.decode(buffer));
        }
    });
}

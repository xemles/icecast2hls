#!/usr/bin/liquidsoap

# General settings

set("log.level",3)
set("log.stdout", true)
set("encoder.encoder.export",["artist","title","album","genre","date","tracknumber","comment","track","year","dj","next"])

# Retrieve configuration from environment

hlspath = ref getenv("HLSPATH")

if !hlspath == "" then
  hlspath := "/hls"
end

safe_blank = blank(id="safe_blank")
### Radio logic
playlist = input.http("RELAYURL")

fallback = fallback(track_sensitive=false, [playlist, single("/radio/fallback.ogg"), safe_blank])

### END Radio logic
### Outputs

# Define outputs formats

aac_lofi = 
  %ffmpeg(
    format="adts",
    %audio(
      channels=2,
      samplerate=44100,
      codec="libfdk_aac",
      b="32k",
      afterburner=1
    )
  )

aac_midfi = 
  %ffmpeg(
    format="adts",
    %audio(
      channels=2,
      samplerate=44100,
      codec="libfdk_aac",
      b="64k",
      afterburner=1
    )
  )

aac_hifi = 
  %ffmpeg(
    format="adts",
    %audio(
      channels=2,
      samplerate=44100,
      codec="libfdk_aac",
      b="128k",
      afterburner=1
    )
  )

# Defines stream infos that cannot be guessed by liqudisoap

streams_info = [("aac_lofi",(32000,"mp4a.40.2","aac")),
                ("aac_midfi",(64000,"mp4a.40.2","aac")),
                ("aac_hifi",(128000,"mp4a.40.2","aac"))]

# Output to HLS

def segment_name(~position,~extname,stream_name) =
  timestamp = int_of_float(gettimeofday())
  duration = 2
  "#{stream_name}_#{duration}_#{timestamp}_#{position}.aac"
end

def on_file_change(~state,fname) =
  if state == "closed" and file.extension(fname) != '.m3u8' then
    log.important(label="hls", "Segment #{fname} created")
  end
end

output.file.hls(id="output_hls",
                playlist="live.m3u8",
                segment_duration=2.0,
                segments=3,
                segments_overhead=10,
                segment_name=segment_name,
                streams_info=streams_info,
                on_file_change=on_file_change,
                persist=true,
                persist_at="state.config",
                !hlspath,
                [("aac_lofi",aac_lofi), 
                 ("aac_midfi", aac_midfi), 
                 ("aac_hifi", aac_hifi)],
                fallback)

### END Outputs


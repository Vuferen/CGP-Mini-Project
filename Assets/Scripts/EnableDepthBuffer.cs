using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnableDepthBuffer : MonoBehaviour
{
    void Awake()
    {
        Camera cam = GetComponent<Camera>();
        cam.depthTextureMode = DepthTextureMode.Depth;
    }
}

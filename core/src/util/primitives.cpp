#include "primitives.h"

#include "glm/gtc/matrix_transform.hpp"
#include "glm/gtc/type_ptr.hpp"

namespace Primitives {

    static bool s_initialized;
    static std::unique_ptr<ShaderProgram> s_shader;
    static std::unique_ptr<VertexLayout> s_layout;

    static const GLchar* s_vert = R"END(
    #ifdef GL_ES
    precision mediump float;
    #endif

    attribute vec2 a_position;

    uniform mat4 u_proj;

    void main() {
        gl_Position = u_proj * vec4(a_position, 1.0, 1.0);
    }

    )END";

    static const GLchar* s_frag = R"END(
    #ifdef GL_ES
    precision mediump float;
    #endif

    uniform vec3 u_color;

    void main() {
        gl_FragColor = vec4(u_color, 1.0);
    }

    )END";

    void init(glm::vec2 _resolution) {
        if (!s_initialized) {
            glm::mat4 proj = glm::ortho(0.f, _resolution.x, _resolution.y, 0.f, -1.f, 1.f);

            s_shader = std::unique_ptr<ShaderProgram>(new ShaderProgram());
            s_shader->setSourceStrings(s_frag, s_vert);
            s_shader->setUniformf("u_color", 1.f, 1.f, 1.f);
            s_shader->setUniformMatrix4f("u_proj", glm::value_ptr(proj));

            s_initialized = true;

            s_layout = std::unique_ptr<VertexLayout>(new VertexLayout({
                {"a_position", 2, GL_FLOAT, false, 0},
            }));
        }
    }

    void drawLine(const glm::vec2& _origin, const glm::vec2& _destination) {
        glm::vec2 verts[2] = {
            glm::vec2(_origin.x, _origin.y),
            glm::vec2(_destination.x, _destination.y)
        };

        s_shader->use();

        glDisable(GL_DEPTH_TEST);

        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

        s_layout->enable(*s_shader, 0, &verts);

        glDrawArrays(GL_LINES, 0, 2);
        
        glEnable(GL_DEPTH_TEST);
    }
}
